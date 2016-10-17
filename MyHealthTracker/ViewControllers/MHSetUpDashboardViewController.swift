//
//  MHSetUpDashboardViewController.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 12/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import UIKit
import CareKit
import THSegmentedControl

class MHSetUpDashboardViewController: UIViewController,UITextFieldDelegate,MHCarePlanViewControllerProtocol {

    let MAXIMUM_MEDICATIONS_IN_SYSTEM = 2
    var carePlan:OCKCarePlanStore?
    var medicationsInCarePlan:Int = 0
    
    //UI
    @IBOutlet var medicationsInTheSystemLabel: UILabel!

    @IBOutlet var formView: UIView!
    
    @IBOutlet var medicationNameTextfield: UITextField!
    @IBOutlet var dosisFieldTextfield: UITextField!
    @IBOutlet var segmenControlSuperview: UIView!
    let segmentControl:THSegmentedControl = THSegmentedControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpWeeklyView()
        self.segmenControlSuperview.addSubview(self.segmentControl)
        
        self.segmentControl.topAnchor.constraint(equalTo: self.segmenControlSuperview.topAnchor).isActive = true
        self.segmentControl.bottomAnchor.constraint(equalTo: self.segmenControlSuperview.bottomAnchor).isActive = true
        self.segmentControl.leftAnchor.constraint(equalTo: self.segmenControlSuperview.leftAnchor).isActive = true
        self.segmentControl.rightAnchor.constraint(equalTo: self.segmenControlSuperview.rightAnchor).isActive = true
        self.segmentControl.translatesAutoresizingMaskIntoConstraints = false
        
        self.checkFormAvailability()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private Methods
    
    func checkFormAvailability(){

        self.carePlan?.activities(with: .intervention, completion: { (returned:Bool, listActivities:[OCKCarePlanActivity], error:Error?) in

            self.medicationsInCarePlan = listActivities.count
            if (listActivities.count == self.MAXIMUM_MEDICATIONS_IN_SYSTEM){

                DispatchQueue.main.async {
                    self.medicationsInTheSystemLabel.text = "Sorry you already have 2 medications in your system";
                    self.medicationsInTheSystemLabel.textAlignment = .center
                    self.formView.isUserInteractionEnabled = false;
                    self.formView.alpha = 0.5;
                }
            }
            else{
                DispatchQueue.main.async {
                    self.medicationsInTheSystemLabel.text = "Medications in your system: \(listActivities.count)";
                }
            }
        })
    }
    
    // MARK: - Privated Methods
    
    func setUpWeeklyView(){
        
        let segments = ["M","T","W","T","F","S","Su"]
        var i = 0
        for day in segments
        {
            self.segmentControl.insertSegment(withTitle: day, at: UInt(i))
            i = i+1
        }
    }
    
    func clearFields()
    {
        self.dosisFieldTextfield.text = ""
        self.medicationNameTextfield.text = ""
    }
    
    // MARK: - Buttons
    
    @IBAction func addButtonTouchedIn(_ sender: AnyObject) {
        
        if let textDosis = self.dosisFieldTextfield.text {
            if let medicationName = self.medicationNameTextfield.text {
            
                let dosisInt = Int(textDosis)

                if dosisInt != nil && dosisInt! > 0 && self.segmentControl.selectedIndexes()!.count > 0 {
                
                    let startDateComponents = DateComponents(year: 2016, month: 01, day: 01)
                    var occurrencesOnEachDay = [0,0,0,0,0,0,0]
                    for index in self.segmentControl.selectedIndexes()!
                    {
                        let indexInt = index as! Int
                        switch indexInt {
                        case 0:
                            occurrencesOnEachDay[1] = dosisInt!
                        case 6:
                            occurrencesOnEachDay[0] = dosisInt!
                        default:
                            occurrencesOnEachDay[indexInt+1] = dosisInt!
                        }
                    }
                    
                    let schedule = OCKCareSchedule.weeklySchedule(withStartDate: startDateComponents, occurrencesOnEachDay: occurrencesOnEachDay as [NSNumber])
                    
                    var activityType = ActivityType.takeMedication1.rawValue
                    if self.medicationsInCarePlan == 1 {
                        activityType = ActivityType.takeMedication2.rawValue
                    }
                    let medicationActivity = OCKCarePlanActivity.intervention(withIdentifier: activityType, groupIdentifier: "painMedication", title: medicationName, text: nil, tintColor: UIColor.blue, instructions: "Take with food", imageURL: nil, schedule: schedule, userInfo: nil)
                    self.carePlan?.add(medicationActivity, completion: { (completed:Bool, error:Error?) in
                        if (!completed && error != nil)
                        {
                            print("The Ibuprofen could be not saved, error:\(error!)")
                        }
                    })
                    
                    self.checkFormAvailability()
                    self.clearFields()
                    
                    return;
                }
            }
        }
        
        let alert:UIAlertController = UIAlertController(title: "Info", message: "Please check the form", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARKS: - TextfieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return false
    }
}
