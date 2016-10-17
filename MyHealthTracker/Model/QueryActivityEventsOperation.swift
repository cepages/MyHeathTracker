//
//  QueryActivityEventsOperation.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import CareKit

class QueryActivityEventsOperation: Operation {
    // MARK: Properties
    
    fileprivate let store: OCKCarePlanStore
    
    fileprivate let activityIdentifier: String
    
    fileprivate let startDate: DateComponents
    
    fileprivate let endDate: DateComponents
    
    fileprivate(set) var dailyEvents: DailyEvents?
    
    // MARK: Initialization
    
    init(store: OCKCarePlanStore, activityIdentifier: String, startDate: DateComponents, endDate: DateComponents) {
        self.store = store
        self.activityIdentifier = activityIdentifier
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // MARK: NSOperation
    
    override func main() {
        // Do nothing if the operation has been cancelled.
        guard !isCancelled else { return }
        
        // Find the activity with the specified identifier in the store.
        guard let activity = findActivity() else { return }
        
        /*
         Create a semaphore to wait for the asynchronous call to `enumerateEventsOfActivity`
         to complete.
         */
        let semaphore = DispatchSemaphore(value: 0)
        
        // Query for events for the activity between the requested dates.
        self.dailyEvents = DailyEvents()
        
        DispatchQueue.main.async { // <rdar://problem/25528295> [CK] OCKCarePlanStore query methods crash if not called on the main thread
            self.store.enumerateEvents(of: activity, startDate: self.startDate as DateComponents, endDate: self.endDate as DateComponents, handler: { event, _ in
                if let event = event {
                    self.dailyEvents?[event.date].append(event)
                }
                }, completion: { _, _ in
                    // Use the semaphore to signal that the query is complete.
                    semaphore.signal()
            })
        }
        
        // Wait for the semaphore to be signalled.
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    // MARK: Convenience
    
    fileprivate func findActivity() -> OCKCarePlanActivity? {
        /*
         Create a semaphore to wait for the asynchronous call to `activityForIdentifier`
         to complete.
         */
        let semaphore = DispatchSemaphore(value: 0)
        
        var activity: OCKCarePlanActivity?
        
        DispatchQueue.main.async { // <rdar://problem/25528295> [CK] OCKCarePlanStore query methods crash if not called on the main thread
            self.store.activity(forIdentifier: self.activityIdentifier) { success, foundActivity, error in
                activity = foundActivity
                if !success {
                    print(error?.localizedDescription)
                }
                
                // Use the semaphore to signal that the query is complete.
                semaphore.signal()
            }
        }
        
        // Wait for the semaphore to be signalled.
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return activity
    }
}



struct DailyEvents {
    // MARK: Properties
    
    fileprivate var mappedEvents: [DateComponents: [OCKCarePlanEvent]]
    
    var allEvents: [OCKCarePlanEvent] {
        return Array(mappedEvents.values.joined())
    }
    
    var allDays: [DateComponents] {
        return Array(mappedEvents.keys)
    }
    
    subscript(day: DateComponents) -> [OCKCarePlanEvent] {
        get {
            if let events = mappedEvents[day] {
                return events
            }
            else {
                return []
            }
        }
        
        set(newValue) {
            mappedEvents[day] = newValue
        }
    }
    
    // MARK: Initialization
    
    init() {
        mappedEvents = [:]
    }
}
