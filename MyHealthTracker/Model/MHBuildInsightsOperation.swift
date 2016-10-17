//
//  BuildInsightsOperation.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import CareKit

class MHBuildInsightsOperation: Operation {

    // MARK: Properties
    
    var medicationEvents: DailyEvents?
    var medication2Events: DailyEvents?
    var bloodGlucose: DailyEvents?
    var heartRate: DailyEvents?

    
    fileprivate(set) var insights = [OCKInsightItem.emptyInsightsMessage()]
    
    // MARK: NSOperation
    
    override func main() {
        // Do nothing if the operation has been cancelled.
        guard !isCancelled else { return }
        
        // Create an array of insights.
        var newInsights = [OCKInsightItem]()
        
        if let insight = createBloodGlucoseInsight() {
            newInsights.append(insight)
        }
        
        // Store any new insights thate were created.
        if !newInsights.isEmpty {
            insights = newInsights
        }
    }
    
    func createBloodGlucoseInsight() -> OCKInsightItem? {
        // Make sure there are events to parse.
        guard let bloodGlucose = bloodGlucose, let heartRate = heartRate else { return nil }
        
        // Determine the date to start pain/medication comparisons from.
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = -7
        
        let startDate = calendar.date(byAdding: components as DateComponents, to: Date())!
        
        // Create formatters for the data.
        let dayOfWeekFormatter = DateFormatter()
        dayOfWeekFormatter.dateFormat = "E"
        
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "Md", options: 0, locale: shortDateFormatter.locale)
        
        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        
        /*
         Loop through 7 days, collecting medication adherance and pain scores
         for each.
         */
        var medicationValues = [Float]()
        var medicationLabels = [String]()
        var bloodGlucoseValues = [Int]()
        var bloodGlucoseLabels = [String]()
        var heartRateValues = [Int]()
        var heartRateLabels = [String]()
        var axisTitles = [String]()
        var axisSubtitles = [String]()
        
        for offset in 0..<7 {
            // Determine the day to components.
            components.day = offset
            let dayDate = calendar.date(byAdding: components as DateComponents, to: startDate)!
            let dayComponents = calendar.dateComponents([.year, .month, .day, .era], from: dayDate)
            
            // Store the pain result for the current day.
            if let result = bloodGlucose[dayComponents].first?.result, let score = Int(result.valueString) , score > 0 {
                bloodGlucoseValues.append(score)
                bloodGlucoseLabels.append(result.valueString)
            }
            else {
                bloodGlucoseValues.append(0)
                bloodGlucoseLabels.append(NSLocalizedString("N/A", comment: ""))
            }
            
            // Store the pain result for the current day.
            if let result = heartRate[dayComponents].first?.result, let score = Int(result.valueString) , score > 0 {
                heartRateValues.append(score)
                heartRateLabels.append(result.valueString)
            }
            else {
                heartRateValues.append(0)
                heartRateLabels.append(NSLocalizedString("N/A", comment: ""))
            }
            
            var totalMedicationsSaved = 0;
            
            var adherenceMedication1 = Float(0)
            if let medicationEvents = medicationEvents {
                
                let medicationEventsForDay = medicationEvents[dayComponents]
                if medicationEventsForDay.count > 0 {
                    totalMedicationsSaved = totalMedicationsSaved + 1;
                }
                if let adherence = percentageEventsCompleted(medicationEventsForDay) , adherence > 0.0 {
                    adherenceMedication1 = adherence
                }
            }
            
            var adherenceMedication2 = Float(0)
            if let medication2Events = medication2Events
            {

                let medication2EventsForDay = medication2Events[dayComponents]
                if medication2EventsForDay.count > 0 {
                    totalMedicationsSaved = totalMedicationsSaved + 1;
                }
                if let adherence = percentageEventsCompleted(medication2EventsForDay) , adherence > 0.0 {
                    adherenceMedication2 = adherence
                }
            }

            var totalAdherence = Float(0)
            if totalMedicationsSaved != 0 {
                totalAdherence = (adherenceMedication1 + adherenceMedication2) / Float(totalMedicationsSaved)
            }
            if totalAdherence > 0.0 {
                
                let totalScaledAdeherence = totalAdherence * 100.0
                
                medicationValues.append(totalScaledAdeherence)
                medicationLabels.append(percentageFormatter.string(from: NSNumber(value: totalAdherence))!)
            }
            else {
                medicationValues.append(0.0)
                medicationLabels.append(NSLocalizedString("N/A", comment: ""))
            }
            
            axisTitles.append(dayOfWeekFormatter.string(from: dayDate))
            axisSubtitles.append(shortDateFormatter.string(from: dayDate))
        }
        
        // Create a `OCKBarSeries` for each set of data.
        let bloodGlucoseBarSeries = OCKBarSeries(title: "Blood glucose", values: bloodGlucoseValues as [NSNumber], valueLabels: bloodGlucoseLabels, tintColor: UIColor.blue)
        let hearthGlucoseBarSeries = OCKBarSeries(title: "Heart eate", values: heartRateValues as [NSNumber], valueLabels: heartRateLabels, tintColor: UIColor.orange)
        let medicationBarSeries = OCKBarSeries(title: "Medication adherence", values: medicationValues as [NSNumber], valueLabels: medicationLabels, tintColor: UIColor.lightGray)
        
        /*
         Add the series to a chart, specifing the scale to use for the chart
         rather than having CareKit scale the bars to fit.
         */
        let chart = OCKBarChart(title: "Vitals / Medication adherence",
                                text: nil,
                                tintColor: UIColor.blue,
                                axisTitles: axisTitles,
                                axisSubtitles: axisSubtitles,
                                dataSeries: [bloodGlucoseBarSeries, hearthGlucoseBarSeries, medicationBarSeries],
                                minimumScaleRangeValue: 0,
                                maximumScaleRangeValue: 10)
        
        return chart
    }
    
    /**
     For a given array of `OCKCarePlanEvent`s, returns the percentage that are
     marked as completed.
     */
    fileprivate func percentageEventsCompleted(_ events: [OCKCarePlanEvent]) -> Float? {
        guard !events.isEmpty else { return nil }
        
        let completedCount = events.filter({ event in
            event.state == .completed
        }).count
        
        return Float(completedCount) / Float(events.count)
    }
}

/**
 An extension to `SequenceType` whose elements are `OCKCarePlanEvent`s. The
 extension adds a method to return the first element that matches the day
 specified by the supplied `NSDateComponents`.
 */
extension Sequence where Iterator.Element: OCKCarePlanEvent {
    
    func eventForDay(_ dayComponents: NSDateComponents) -> Iterator.Element? {
        for event in self where
            event.date.year == dayComponents.year &&
                event.date.month == dayComponents.month &&
                event.date.day == dayComponents.day {
                    return event
        }
        
        return nil
    }
}
