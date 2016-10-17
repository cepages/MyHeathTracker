//
//  MHHealthTabBarViewController.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 12/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import UIKit
import CareKit
import ResearchKit

class MHHealthTabBarViewController: UITabBarController {

    var careCardController:OCKCareCardViewController?
    var symptomKitController:OCKSymptomTrackerViewController?
    var insightController:OCKInsightsViewController?
    let carePlanManager:MHCarePlanManager = MHCarePlanManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.carePlanManager.delegate = self
        
        self.careCardController = OCKCareCardViewController(carePlanStore: self.carePlanManager.carePlanStore)
        let navigationCareCardViewController = UINavigationController(rootViewController: self.careCardController!)
        navigationCareCardViewController.tabBarItem.title = "Medication"
        
        self.symptomKitController = OCKSymptomTrackerViewController(carePlanStore: self.carePlanManager.carePlanStore)
        self.symptomKitController!.delegate = self;
        let navigationSymptomViewController = UINavigationController(rootViewController: self.symptomKitController!)
        navigationSymptomViewController.tabBarItem.title = "Symtoms"
        
        self.insightController = OCKInsightsViewController(insightItems: self.carePlanManager.insights, headerTitle: "Weekly Charts", headerSubtitle: "")
        let navigationInsightViewController = UINavigationController(rootViewController: self.insightController!)
        navigationInsightViewController.tabBarItem.title = "Insight"
        // Start to build the initial array of insights.
        self.carePlanManager.updateInsights()
        
        if self.viewControllers != nil {
            self.viewControllers!.insert(navigationCareCardViewController, at: 0)
            self.viewControllers!.insert(navigationSymptomViewController, at: 1)
            self.viewControllers!.insert(navigationInsightViewController, at: 2)
        }
        else{
            var viewControllers = [UIViewController]()
            viewControllers.insert(navigationCareCardViewController, at: 0)
            viewControllers.insert(navigationSymptomViewController, at: 1)
            viewControllers.insert(navigationInsightViewController, at: 2)

            self.setViewControllers(viewControllers, animated: false);
        }
        
        if self.viewControllers!.count > 3 {
            for index in 3...viewControllers!.count - 1
            {
                let viewController = self.viewControllers![index]
                if let carePlanVC = viewController as? MHCarePlanViewControllerProtocol {
                    carePlanVC.carePlan = self.carePlanManager.carePlanStore
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MHHealthTabBarViewController: MHCarePlanManagerDelegate {
    func carePlanStoreManager(_ manager: MHCarePlanManager, didUpdateInsights insights: [OCKInsightItem])
    {
        self.insightController?.items = insights
    }
}

extension MHHealthTabBarViewController: OCKSymptomTrackerViewControllerDelegate {
    
    /// Called when the user taps an assessment on the `OCKSymptomTrackerViewController`.
    func symptomTrackerViewController(_ viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        // Lookup the assessment the row represents.
        guard let activityType = ActivityType(rawValue: assessmentEvent.activity.identifier) else { return }
        guard let sampleAssessment = self.carePlanManager.setUpCatePlan.activityWithType(activityType) as? MHAssessment else { return }
        
        /*
         Check if we should show a task for the selected assessment event
         based on its state.
         */
        guard assessmentEvent.state == .initial ||
            assessmentEvent.state == .notCompleted ||
            (assessmentEvent.state == .completed && assessmentEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRun: nil)
        taskViewController.delegate = self
        
        present(taskViewController, animated: true, completion: nil)
    }
}

extension MHHealthTabBarViewController: ORKTaskViewControllerDelegate {
    
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        defer {
            dismiss(animated: true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .completed else { return }
        
        // Determine the event that was completed and the `SampleAssessment` it represents.
        guard let event = self.symptomKitController!.lastSelectedAssessmentEvent,
            let activityType = ActivityType(rawValue: event.activity.identifier),
            let sampleAssessment = self.carePlanManager.setUpCatePlan.activityWithType(activityType) as? MHAssessment else { return }
        
        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
        
        // Check assessment can be associated with a HealthKit sample.
        if let healthSampleBuilder = sampleAssessment as? MHHealthSampleBuilder {
            // Build the sample to save in the HealthKit store.
            let sample = healthSampleBuilder.buildSampleWithTaskResult(taskViewController.result)
            let sampleTypes: Set<HKSampleType> = [sample.sampleType]
            
            // Requst authorization to store the HealthKit sample.
            let healthStore = HKHealthStore()
            healthStore.requestAuthorization(toShare: sampleTypes, read: sampleTypes, completion: { success, _ in
                // Check if authorization was granted.
                if !success {
                    /*
                     Fall back to saving the simple `OCKCarePlanEventResult`
                     in the `OCKCarePlanStore`.
                     */
                    self.completeEvent(event, inStore: self.carePlanManager.carePlanStore, withResult: carePlanResult)
                    return
                }
                
                // Save the HealthKit sample in the HealthKit store.
                healthStore.save(sample, withCompletion: { success, _ in
                    if success {
                        /*
                         The sample was saved to the HealthKit store. Use it
                         to create an `OCKCarePlanEventResult` and save that
                         to the `OCKCarePlanStore`.
                         */
                        let healthKitAssociatedResult = OCKCarePlanEventResult(
                            quantitySample: sample,
                            quantityStringFormatter: nil,
                            display: healthSampleBuilder.unit,
                            displayUnitStringKey: healthSampleBuilder.localizedUnitForSample(sample),
                            userInfo: nil
                        )
                        
                        self.completeEvent(event, inStore: self.carePlanManager.carePlanStore, withResult: healthKitAssociatedResult)
                    }
                    else {
                        /*
                         Fall back to saving the simple `OCKCarePlanEventResult`
                         in the `OCKCarePlanStore`.
                         */
                        self.completeEvent(event, inStore:self.carePlanManager.carePlanStore, withResult: carePlanResult)
                    }
                    
                })
            })
        }
        else {
            // Update the event with the result.
            completeEvent(event, inStore: self.carePlanManager.carePlanStore, withResult: carePlanResult)
        }
        
    }
    
    func completeEvent(_ event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.update(event, with: result, state: .completed) { success, _, error in
            if !success {
                print(error?.localizedDescription)
            }
        }
    }
}


