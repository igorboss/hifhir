//
//  SecondViewController.swift
//  HiFHIR
//
//  Created by Igor Bossenko on 20/12/2016.
//  Copyright © 2016 Nortal. All rights reserved.
//

import UIKit

class SecondViewController: UITableViewController {

    var weightData = Array<Dictionary<String, String>>()
    var heightData = Array<Dictionary<String, String>>()
    
    @IBOutlet var tblView: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LabelCell" )

        var loading = Dictionary<String,String>()
        loading["issued"]="Loading"
        loading["value"]="..."
        loading["unit"]="..."

        weightData.append(loading)
        heightData.append(loading)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        let defaults = UserDefaults.standard
        let serverAddr = defaults.string(forKey: "FHIRserver")
        let patientID = defaults.string(forKey: "PatientID")
        
        let lastWeightObservationsUrl = serverAddr! + "/Observation?code=27113001&subject="+patientID!+"&_sort:desc=issued&_count=10"
        getObservations(urlString: lastWeightObservationsUrl, completion: {(result: Array<Dictionary<String, String>>)->Void in
            self.weightData.removeAll()
            self.weightData = result
            self.tblView.reloadData()
        })
        
        let lastHeightObservationsUrl = serverAddr! + "/Observation?code=50373000&subject="+patientID!+"&_sort:desc=issued&_count=10"
        getObservations(urlString: lastHeightObservationsUrl, completion: {(result: Array<Dictionary<String, String>>)->Void in
            self.heightData.removeAll()
            self.heightData = result
            self.tblView.reloadData()
        })
        
    }
    
    func getObservations(urlString: String, completion:@escaping (_ result : Array<Dictionary<String, String>>) -> Void){
        
        var result = Array<Dictionary<String, String>>()
        
        RESTController.doGet(urlString: urlString, completion: {(data: Data) -> Void in
            do {
                guard let bundle = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    else {
                        print("error trying to convert data to JSON")
                        return
                }
                
                guard let entries = bundle["entry"] as? [Any]
                    else {
                        print("Attrinute 'entry' not found in JSON")
                        return
                }
                for entry in entries {
                    
                    if let observation = entry as? [String: Any] {
                        var dict = Dictionary<String, String>()
                        let id = observation["id"] as! String
                        dict["id"] = id
                        let observationResource = observation["resource"] as? [String: Any]
                        for (key, value) in observationResource! {
                            // access all key / value pairs in dictionary
                            if(key=="issued") {
                                dict["issued"] = value as? String
                            }
                            if(key=="valueQuantity") {
                                let valueQuantity = observationResource?["valueQuantity"] as? [String: Any]
                                for (key, value) in valueQuantity! {
                                    //print("key = \(key), value = \(value)")
                                    if(key=="value") {
                                        let quantity : Double = value as! Double
                                        dict["value"] = String(format:"%g", quantity)
                                    }
                                    if(key=="code") {
                                        dict["unit"] = value as? String
                                    }
                                }
                            }
                        }
                        result.append(dict)
                        
                    } else {
                        print("error converting entry to Observation object")
                        return
                    }
                }
                
                completion(result)
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        
        })
        
    }
    
/*
    func getObservation(urlString: String, completion:@escaping (_ result : Dictionary<String, String>) -> Void){
        
        guard let url = URL(string: urlString) else {
            print("Error: cannot create URL")
            return //result
        }
        var urlRequest = URLRequest(url: url)//, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            // do stuff with response, data & error here
            guard error == nil else {
                print("error calling GET request")
                print(error!)
                return
            }
            guard data != nil else {
                print("Error: did not receive data")
                return
            }
            do {
                guard let bundle = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    else {
                        print("error trying to convert data to JSON")
                        return
                }
                //print(bundle.description)
                
                
                guard let entries = bundle["entry"] as? [Any]
                    else {
                        print("Attrinute 'entry' not found in JSON")
                        return
                }
                for entry in entries {
                    
                    if let observation = entry as? [String: Any] {
                        var dict = Dictionary<String, String>()
                        let id = observation["id"] as! String
                        dict["id"] = id
                        let observationResource = observation["resource"] as? [String: Any]
                        for (key, value) in observationResource! {
                            // access all key / value pairs in dictionary
                            if(key=="issued") {
                                dict["issued"] = value as? String
                            }
                            if(key=="valueQuantity") {
                                let valueQuantity = observationResource?["valueQuantity"] as? [String: Any]
                                for (key, value) in valueQuantity! {
                                    //print("key = \(key), value = \(value)")
                                    if(key=="value") {
                                        let quantity : Double = value as! Double
                                        dict["value"] = String(format:"%g", quantity)
                                    }
                                    if(key=="code") {
                                        dict["unit"] = value as? String
                                    }
                                }
                            }
                        }
                        completion(dict)
                        
                    } else {
                        print("error converting entry to Observation object")
                        return
                    }
                }
                
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
            
        })
        task.resume()
        
        
    }
*/

    //delegate methods
    func numberOfSections(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section==0){
            return "Weight"
        } else if (section==1){
            return "Height"
        } else {
            return "Section \(section)"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 2
        if(section==0){
            return weightData.count
        } else if (section==1){
            return heightData.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseLabelIdentifier = "LabelCell"
        
        //let cell = tblView.dequeueReusableCell(withIdentifier: reuseLabelIdentifier, for: indexPath ) as UITableViewCell
        
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: reuseLabelIdentifier)
        
        // next construction must work in Swift 3.0, but doesn't work
        /*
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseLabelIdentifier) else {
                // Never fails:
                return UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: reuseLabelIdentifier)
            }
            return cell
        }()
        */

        
        if(indexPath.section==0){
            //print(weightData[indexPath.row])
            cell.detailTextLabel?.text = fmtDate(timestamp: weightData[indexPath.row]["issued"]!)
            cell.textLabel?.text = weightData[indexPath.row]["value"]! + " " + weightData[indexPath.row]["unit"]!
            
            return cell
        } else if (indexPath.section==1){
            //print(heightData[indexPath.row])
            cell.detailTextLabel?.text = fmtDate(timestamp: heightData[indexPath.row]["issued"]!)
            cell.textLabel?.text = heightData[indexPath.row]["value"]! + " " + heightData[indexPath.row]["unit"]!
            return cell
        } else {
            cell.textLabel?.text = "N/A Section \(indexPath.section) Row \(indexPath.row)"
        }
        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .insert {
            //deletePlanetIndexPath = indexPath
            //let planetToDelete = planets[indexPath.row]
            //confirmDelete(planetToDelete)
            print("Row \(indexPath.row)  Style \(editingStyle.rawValue) ")
        }
    }
    /*
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var saveAction = UITableViewRowAction(style: .normal, title: "Save", handler: <#T##(UITableViewRowAction, IndexPath) -> Void#>){
            let activityItem
        }
    }
    */
    
    func fmtDate(timestamp:String) -> String {
        if #available(iOS 10.0, *) {
            let ISOFormatter = ISO8601DateFormatter()
            guard let date = ISOFormatter.date(from: timestamp)
            else {
                if timestamp.characters.count < 10 {
                    return timestamp
                }
                let index = timestamp.index(timestamp.startIndex, offsetBy: 10)
                return timestamp.substring(to: index)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy HH:mm"
            return dateFormatter.string(from: date)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
            guard let date = dateFormatter.date(from: timestamp.replacingOccurrences(of: "T", with: " ", options: .literal, range: nil))
            else {
                if timestamp.characters.count < 10 {
                    return timestamp
                }
                let index = timestamp.index(timestamp.startIndex, offsetBy: 10)
                return timestamp.substring(to: index)
            }
            
            dateFormatter.dateFormat = "dd.MM.yy HH:mm"
            return dateFormatter.string(from: date)
        }
        
    }
    
}

