//
//  MHUser.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 12/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import UIKit
import CareKit

class MHCarePlanManager: NSObject {
    
    let setUpCatePlan:MHSetUpCarePlan
    let carePlanStore:OCKCarePlanStore
    
    fileprivate let insightsBuilder: InsightsBuilder

    var insights: [OCKInsightItem] {
        return insightsBuilder.insights
    }
    
    weak var delegate: MHCarePlanManagerDelegate?

    override init() {
        
        let searchPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let myDirectoryURL = URL(fileURLWithPath: applicationSupportPath)
        
        if !FileManager.default.fileExists(atPath: myDirectoryURL.absoluteString, isDirectory: nil) {
            try! FileManager.default.createDirectory(at: myDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        carePlanStore = OCKCarePlanStore(persistenceDirectoryURL: myDirectoryURL)
        setUpCatePlan = MHSetUpCarePlan(carePlanStore: carePlanStore)
        
        self.insightsBuilder = InsightsBuilder(carePlanStore: self.carePlanStore)

        super.init()
        carePlanStore.delegate = self
    }
    
    func updateInsights() {
        insightsBuilder.updateInsights {
            [weak self] completed, newInsights in
            // If new insights have been created, notifiy the delegate.
            guard let carePlanManager = self, let newInsights = newInsights , completed else {
                return
            }
            carePlanManager.delegate?.carePlanStoreManager(carePlanManager, didUpdateInsights: newInsights)
        }
    }
}


extension MHCarePlanManager: OCKCarePlanStoreDelegate {
    func carePlanStoreActivityListDidChange(_ store: OCKCarePlanStore) {
        updateInsights()
    }
    
    func carePlanStore(_ store: OCKCarePlanStore, didReceiveUpdateOf event: OCKCarePlanEvent) {
        updateInsights()
    }
}

protocol MHCarePlanManagerDelegate: class {
    
    func carePlanStoreManager(_ manager: MHCarePlanManager, didUpdateInsights insights: [OCKInsightItem])
    
}
