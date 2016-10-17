//
//  MHCarePlanViewControllerProtocol.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 16/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import CareKit
protocol MHCarePlanViewControllerProtocol: class {
    
    var  carePlan:OCKCarePlanStore? { get set }
}
