//
//  ThirdViewController.swift
//  HiFHIR
//
//  Created by Igor Bossenko on 21/12/2016.
//  Copyright © 2016 Nortal. All rights reserved.
//

import UIKit

class ThirdViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var ftServer: UITextField!
    @IBOutlet var ftPatientID: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.ftPatientID.delegate = self
        self.ftServer.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        
        let serverAddr = defaults.string(forKey: "FHIRserver")
        if (serverAddr != nil && serverAddr != "") {ftServer.text = serverAddr;}
        else {
            ftServer.text = "https://fhir.nortal.com/blaze";
            defaults.set( ftServer.text, forKey: "FHIRserver");
        }
        
        let patientID = defaults.string(forKey: "PatientID")
        if (patientID != nil) {ftPatientID.text = patientID;}
        else {
            ftPatientID.text = "Patient/1";
            defaults.set( ftPatientID.text, forKey: "PatientID");
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onChange(_ sender: UITextField) {
        let defaults = UserDefaults.standard
        let value = sender.text!
        if(sender == ftServer){
            defaults.set( value, forKey: "FHIRserver")
        } else if (sender == ftPatientID) {
            defaults.set( value, forKey: "PatientID")
        }
        defaults.synchronize()

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }



    
    
}
