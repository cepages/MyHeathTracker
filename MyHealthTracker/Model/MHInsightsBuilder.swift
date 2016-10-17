//
//  MHInsightsBuilder.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import CareKit
import ResearchKit

class InsightsBuilder {
    
    /// An array if `OCKInsightItem` to show on the Insights view.
    fileprivate(set) var insights = [OCKInsightItem.emptyInsightsMessage()]
    
    fileprivate let carePlanStore: OCKCarePlanStore
    
    fileprivate let updateOperationQueue = OperationQueue()
    
    weak var delegate: InsightsBuilderDelegate?

    required init(carePlanStore: OCKCarePlanStore) {
        self.carePlanStore = carePlanStore
    }
    
    /**
     Enqueues `NSOperation`s to query the `OCKCarePlanStore` and update the
     `insights` property.
     */
    func updateInsights(_ completion: ((Bool, [OCKInsightItem]?) -> Void)?) {
        // Cancel any in-progress operations.
        updateOperationQueue.cancelAllOperations()
        
        // Get the dates the current and previous weeks.
        let queryDateRange = calculateQueryDateRange()
        
        /*
         Create an operation to query for events for the previous week's
         `TakeMedication1` activity.
         */
        
        let medication1EventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                     activityIdentifier: ActivityType.takeMedication1.rawValue,
                                                                     startDate: queryDateRange.start,
                                                                     endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week's
         `TakeMedication2` activity.
         */
        
        let medication2EventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                      activityIdentifier: ActivityType.takeMedication2.rawValue,
                                                                      startDate: queryDateRange.start,
                                                                      endDate: queryDateRange.end)
        /*
         Create an operation to query for events for the previous week and
         current weeks' `BloodGlucose` assessment.
         */
        let bloodGlucoseEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                   activityIdentifier: ActivityType.bloodGlucose.rawValue,
                                                                   startDate: queryDateRange.start,
                                                                   endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week and
         current weeks' `BloodGlucose` assessment.
         */
        let hearthEventsEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                       activityIdentifier: ActivityType.heartRate.rawValue,
                                                                       startDate: queryDateRange.start,
                                                                       endDate: queryDateRange.end)
        
        /*
         Create a `BuildInsightsOperation` to create insights from the data
         collected by query operations.
         */
        let buildInsightsOperation = MHBuildInsightsOperation()
        
        /*
         Create an operation to aggregate the data from query operations into
         the `BuildInsightsOperation`.
         */
        let aggregateDataOperation = BlockOperation {
            // Copy the queried data from the query operations to the `BuildInsightsOperation`.
            buildInsightsOperation.medicationEvents = medication1EventsOperation.dailyEvents
            buildInsightsOperation.medication2Events = medication2EventsOperation.dailyEvents
            buildInsightsOperation.bloodGlucose = bloodGlucoseEventsOperation.dailyEvents
            buildInsightsOperation.heartRate = hearthEventsEventsOperation.dailyEvents
        }
        
        /*
         Use the completion block of the `BuildInsightsOperation` to store the
         new insights and call the completion block passed to this method.
         */
        buildInsightsOperation.completionBlock = { [unowned buildInsightsOperation] in
            let completed = !buildInsightsOperation.isCancelled
            let newInsights = buildInsightsOperation.insights
            
            // Call the completion block on the main queue.
            OperationQueue.main.addOperation {
                if completed {
                    completion?(true, newInsights)
                }
                else {
                    completion?(false, nil)
                }
            }
        }
        
        // The aggregate operation is dependent on the query operations.
        aggregateDataOperation.addDependency(medication1EventsOperation)
        aggregateDataOperation.addDependency(medication2EventsOperation)
        aggregateDataOperation.addDependency(bloodGlucoseEventsOperation)
        aggregateDataOperation.addDependency(hearthEventsEventsOperation)
        
        // The `BuildInsightsOperation` is dependent on the aggregate operation.
        buildInsightsOperation.addDependency(aggregateDataOperation)
        
        // Add all the operations to the operation queue.
        updateOperationQueue.addOperations([
            medication1EventsOperation,
            medication2EventsOperation,
            bloodGlucoseEventsOperation,
            hearthEventsEventsOperation,
            aggregateDataOperation,
            buildInsightsOperation
            ], waitUntilFinished: false)
    }

    
    fileprivate func calculateQueryDateRange() -> (start: DateComponents, end: DateComponents) {
        let calendar = Calendar.current
        let now = Date()
        
        let currentWeekRange = calendar.weekDatesForDate(now)
        let previousWeekRange = calendar.weekDatesForDate(currentWeekRange.start.addingTimeInterval(-1))
        
        let queryRangeStart = calendar.dateComponents([.year, .month, .day, .era], from: previousWeekRange.start)
        let queryRangeEnd = calendar.dateComponents([.year, .month, .day, .era], from: now)
        
        return (start: queryRangeStart, end: queryRangeEnd)
    }
}

protocol InsightsBuilderDelegate: class {
    func insightsBuilder(_ insightsBuilder: InsightsBuilder, didUpdateInsights insights: [OCKInsightItem])
}
