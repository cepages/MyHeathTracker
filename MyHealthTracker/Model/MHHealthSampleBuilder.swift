//
//  MHHealthSampleBuilder.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import ResearchKit

/**
 A protocol that defines the methods and properties required to be able to save
 an `ORKTaskResult` to a `ORKCarePlanStore` with an associated `HKQuantitySample`.
 */
protocol MHHealthSampleBuilder {
    var quantityType: HKQuantityType { get }
    
    var unit: HKUnit { get }
    
    func buildSampleWithTaskResult(_ result: ORKTaskResult) -> HKQuantitySample
    
    func localizedUnitForSample(_ sample: HKQuantitySample) -> String
}
