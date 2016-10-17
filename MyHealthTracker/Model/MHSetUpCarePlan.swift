//
//  MHSetUpCarePlan.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import ResearchKit
import CareKit

class MHSetUpCarePlan: NSObject {

    /// An array of `Activity`s used in the app.
    let activities: [MHActivity] = [
        MHBloodGlucose(),
        MHHeartRate()
    ]
    
    required init(carePlanStore: OCKCarePlanStore) {
        super.init()
        
        // Populate the store with the sample activities.
        for sampleActivity in activities {
            let carePlanActivity = sampleActivity.carePlanActivity()
            
            carePlanStore.add(carePlanActivity) { success, error in
                if !success {
                    print(error?.localizedDescription)
                }
            }
        }
        
    }
    
    /// Returns the `Activity` that matches the supplied `ActivityType`.
    func activityWithType(_ type: ActivityType) -> MHActivity? {
        for activity in activities where activity.activityType == type {
            return activity
        }
        
        return nil
    }
    
}
