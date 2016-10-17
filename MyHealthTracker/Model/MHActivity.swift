//
//  MHActivity.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import CareKit

/**
 Protocol that defines the properties and methods for sample activities.
 */
protocol MHActivity {
    var activityType: ActivityType { get }
    
    func carePlanActivity() -> OCKCarePlanActivity
}


/**
 Enumeration of strings used as identifiers for the `SampleActivity`s used in
 the app.
 */
enum ActivityType: String {
    case bloodGlucose
    case heartRate
    case takeMedication1
    case takeMedication2
}

