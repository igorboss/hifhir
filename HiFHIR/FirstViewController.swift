//
//  FirstViewController.swift
//  HiFHIR
//
//  Created by Igor Bossenko on 20/12/2016.
//  Copyright © 2016 Nortal. All rights reserved.
//

import UIKit
import HealthKit

class FirstViewController: UIViewController {
    @IBOutlet var AgeValueLabel: UILabel!
    @IBOutlet var HeightValueLabel: UILabel!
    @IBOutlet var GenderValueLabel: UILabel!
    @IBOutlet var WeightValueLabel: UILabel!
    @IBOutlet var BMRValueLabel: UILabel!
    @IBOutlet var BMIValueLabel: UILabel!
    
    var weightInKilograms: Double = 0
    var heightInCentimeters: Double = 0
    var ageInYears: Int = 0
    var biologicalSex: HKBiologicalSex? = nil
    
    var healthStore: HKHealthStore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // Set up an HKHealthStore, asking the user for read/write permissions. The profile view controller is the
        // first view controller that's shown to the user, so we'll ask for all of the desired HealthKit permissions now.
        // In your own app, you should consider requesting permissions the first time a user wants to interact with HealthKit data.
        if HKHealthStore.isHealthDataAvailable() {
            healthStore =  HKHealthStore()
        } else {
            print("Health data not available")
            return 
        }
        
        let writeDataTypes: Set<HKSampleType> = dataTypesToWrite()
        let readDataTypes: Set<HKObjectType> = dataTypesToRead()
        
        healthStore?.requestAuthorization(toShare: writeDataTypes, read: readDataTypes, completion: {
            (success, error) in
            if success {
                print("healthStore initisalization succeeded")
            } else {
                print(error.debugDescription)
            }
        })

        
        DispatchQueue.main.async() {
            // Update the user interface based on the current user's health information.
            self.getUsersHeight()
            self.getUsersWeight()
            self.getUserAge()
            self.getUserGender()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            // Put your code which should be executed with a delay here
            let bmr = self.getBMR()
            if ( bmr != 0 ) {
                self.BMRValueLabel.text = String(bmr) + " kcal per day"
            }
            
            let bmi = self.getBMI()
            if ( bmi != 0 ) {
                let bmiString: String = NumberFormatter.localizedString(from: bmi as NSNumber, number: NumberFormatter.Style.decimal)
                self.BMIValueLabel.text = bmiString
            }
        })

        
    }
    
    
    private func dataTypesToWrite() -> Set<HKSampleType> {
        
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        
        let writeDataTypes: Set<HKSampleType> = [heightType, weightType]
        
        return writeDataTypes
    }
    
    private func dataTypesToRead() -> Set<HKObjectType> {
        
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let birthdayType = HKQuantityType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!
        let biologicalSexType = HKQuantityType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
        
        let readDataTypes: Set<HKObjectType> = [heightType, weightType, birthdayType, biologicalSexType]
        
        return readDataTypes
    }

    
    private func getUserAge() -> Void
    {
        var birthYear: Int = 0
        
        do {
            if #available(iOS 10.0, *) {
                var dateOfBirth: DateComponents? = nil
                dateOfBirth = try self.healthStore?.dateOfBirthComponents()
                birthYear = (dateOfBirth?.year!)!
            } else {
                // Fallback on earlier versions
                var dateOfBirth: Date! = nil
                dateOfBirth = try self.healthStore?.dateOfBirth()
                
                let calendar = Calendar.current
                birthYear = calendar.component(.year, from: dateOfBirth)
            }
        } catch {
            print("Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.")
            return
        }
        
        if(birthYear != 0){
            let date = Date()
            let calendar = Calendar.current
            self.ageInYears = calendar.component(.year, from: date) - birthYear
            
            AgeValueLabel.text = String(self.ageInYears)
        }
        
    }
    
    private func getUserGender() -> Void
    {
        let biologicalSexObject: HKBiologicalSexObject!
        do {
            biologicalSexObject = try self.healthStore!.biologicalSex()
        } catch {
            print("Either an error occured fetching the user's biological sex information or none has been stored yet. In your app, try to handle this gracefully.")
            return
        }
        
        self.biologicalSex = biologicalSexObject.biologicalSex
        if (self.biologicalSex == .male) {
            GenderValueLabel.text = "Male"
        } else {
            GenderValueLabel.text = "Female"
        }
    }
    
    private func getUsersHeight() -> Void
    {
        self.heightInCentimeters = 0
        
        let setHeightInformationHandle: ((String) -> Void) = {
            
            [unowned self] (heightValue) -> Void in
            
            // Fetch user's default height unit in inches.
            let lengthFormatter = LengthFormatter()
            lengthFormatter.unitStyle = Formatter.UnitStyle.short
            
            let heightFormatterUnit = LengthFormatter.Unit.centimeter
            let heightUniString: String = lengthFormatter.unitString(fromValue: 10, unit: heightFormatterUnit)
            //let localizedHeightUnitDescriptionFormat: String = NSLocalizedString("Height (%@)", comment: "");
            
            //let heightUnitDescription: String = String(format: localizedHeightUnitDescriptionFormat, heightUniString);
            
            self.HeightValueLabel.text = heightValue + " " + heightUniString
        }
        
        let heightType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        
        // Query to get the user's latest height, if it exists.
        let completion: HKCompletionHandle = {
            
            (mostRecentQuantity, error) -> Void in
            
            guard let mostRecentQuantity = mostRecentQuantity else {
                
                print("Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.")
                
                DispatchQueue.main.async {
                    
                    let heightValue: String = NSLocalizedString("Not available", comment: "")
                    
                    setHeightInformationHandle(heightValue)
                }
                
                return
            }
            
            // Determine the height in the required unit.
            let heightUnit = HKUnit.meterUnit(with: HKMetricPrefix.centi)
            let usersHeight: Double = mostRecentQuantity.doubleValue(for: heightUnit)
            self.heightInCentimeters = usersHeight
            
            // Update the user interface.
            DispatchQueue.main.async {
                
                let heightValue: String = NumberFormatter.localizedString(from: usersHeight as NSNumber, number: NumberFormatter.Style.none)
                
                setHeightInformationHandle(heightValue)
            }
        }
        
        self.healthStore!.mostRecentQuantitySample(ofType: heightType, completion: completion)
    }
    

    
    private func getUsersWeight() -> Void
    {
        self.weightInKilograms = 0
        
        let setWeightInformationHandle: ((String) -> Void) = {
            
            [unowned self] (weightValue) -> Void in
            
            // Fetch user's default height unit in inches.
            let massFormatter = MassFormatter()
            massFormatter.unitStyle = Formatter.UnitStyle.short
            
            let weightFormatterUnit = MassFormatter.Unit.kilogram
            let weightUniString: String = massFormatter.unitString(fromValue: 10, unit: weightFormatterUnit)
            //let localizedHeightUnitDescriptionFormat: String = NSLocalizedString("Weight (%@)", comment: "");
            
            //let weightUnitDescription = String(format: localizedHeightUnitDescriptionFormat, weightUniString);
            
            self.WeightValueLabel.text = weightValue + " " + weightUniString
            
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        
        // Query to get the user's latest weight, if it exists.
        let completion: HKCompletionHandle = {
            (mostRecentQuantity, error) -> Void in
            
            guard let mostRecentQuantity = mostRecentQuantity else {
                
                print("Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.")
                
                DispatchQueue.main.async {
                    
                    let weightValue: String = NSLocalizedString("Not available", comment: "")
                    
                    setWeightInformationHandle(weightValue)
                }
                
                return
            }
            
            // Determine the weight in the required unit.
            let weightUnit = HKUnit.gramUnit(with: HKMetricPrefix.kilo)
            let usersWeight: Double = mostRecentQuantity.doubleValue(for: weightUnit)
            self.weightInKilograms = usersWeight
            
            // Update the user interface.
            DispatchQueue.main.async {
                
                let weightValue: String = NumberFormatter.localizedString(from: usersWeight as NSNumber, number: NumberFormatter.Style.none)
                
                setWeightInformationHandle(weightValue)
            }
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.mostRecentQuantitySample(ofType: weightType, completion: completion)
        }
    }
    

    
    /// Returns BMR value in kilocalories per day. Note that there are different ways of calculating the
    /// BMR. In this example we chose an arbitrary function to calculate BMR based on weight, height, age,
    /// and biological sex.
    private func getBMR() -> Double
    {
        var BMR: Double = 0
        if self.biologicalSex == .male {
            BMR = 66.0 + (13.8 * self.weightInKilograms) + (5.0 * self.heightInCentimeters) - (6.8 * Double(self.ageInYears))
            return BMR
        }
        BMR = 655 + (9.6 * self.weightInKilograms) + (1.8 * self.heightInCentimeters) - (4.7 * Double(self.ageInYears))

        return BMR
    }
  
    /// Returns  body mass index (BMI) is a statistic developed by Adolphe Quetelet in the 1900’s for evaluating body mass.
    /// It is not related to gender and age. It uses the same formula for men as for women and children.
    /// BMI = Bodyweight in kilograms divided by height in meters squared
    private func getBMI() -> Double
    {
        if(self.heightInCentimeters==0){
          return 0
        }
        let y = Double(self.heightInCentimeters) / Double(100)
        return Double(self.weightInKilograms) / (y * y)
    }

    
    @IBAction func weightButtonTouched(_ sender: UIButton) {
        print("weightButtonTouched")
        send2FHIR("weight",value: String(self.weightInKilograms))
    }
    
    @IBAction func heightButtonTouched(_ sender: UIButton) {
        print("heightButtonTouched")
        send2FHIR("height",value: String(self.heightInCentimeters))
    }
    
 
    fileprivate func send2FHIR(_ observationType:String, value:String) -> Void
    {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "EET")
        let timeStamp = dateFormatter.string(from: now)
        
        let defaults = UserDefaults.standard
        var FhirServer : String = defaults.string(forKey: "FHIRserver")!
        let patientID : String = defaults.string(forKey: "PatientID")!
        if( FhirServer == "" || patientID == ""){
            print("Default FHIR server and/or PatientID are not specified")
            return
        }
        // drop ending slashes from FhirServer address
        if let lastchar = FhirServer.characters.last {
            if ["/", ",", ".", "-", "?"].contains(lastchar) {
                FhirServer = String(FhirServer.characters.dropLast())
            }
        }
        
        var unitShort = ""
        var unitLong = ""
        var snomedCode = ""
        var snomedDescription = ""
        if(observationType=="weight"){
            unitShort = "kg"
            unitLong = "kilogram"
            snomedCode = "27113001"
            snomedDescription = "Body weight"
        } else if(observationType=="height"){
            unitShort = "cm"
            unitLong = "centimeter"
            snomedCode = "50373000"
            snomedDescription = "Body height measure"
        }
        
        var body = "{";
        body += " \"resourceType\": \"Observation\", \"id\": \"\(observationType)-sample-IBO\", \"status\": \"final\", ";
        body += " \"code\": {\"coding\":[{\"system\": \"http://snomed.info/sct\", \"code\": \"\(snomedCode)\",\"display\":\"\(snomedDescription)\"}]}, ";
        body += " \"subject\": {\"reference\": \"\(patientID)\"}, ";
        body += " \"issued\": \"\(timeStamp)\", ";
        body += " \"valueQuantity\": {\"value\": \"\(value)\", \"unit\": \"\(unitLong)\", \"system\": \"http://unitsofmeasure.org\", \"code\": \"\(unitShort)\"}";
        body += "}";
        
        let url = FhirServer + "/Observation/" + observationType + "-sample-IBO"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil && data != nil else {
                // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            let httpStatus = response as! HTTPURLResponse
            if  httpStatus.statusCode == 200 || httpStatus.statusCode == 201 {
                print("Great success! Status = \(httpStatus.statusCode), Location=\(httpStatus.allHeaderFields["Location"])" )
            } else {
                print("Something lets wrong: \(response)")
            }
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString)")
        })
        task.resume()
        
        
    }


}

