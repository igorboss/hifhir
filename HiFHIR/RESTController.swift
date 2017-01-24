//
//  RESTController.swift
//  HiFHIR
//
//  Created by Igor Bossenko on 12/01/2017.
//  Copyright © 2017 Nortal. All rights reserved.
//

import Foundation

class RESTController {

    class func doGet(urlString: String, completion:@escaping (_ data : Data) -> Void){
        
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
            completion(data!)
            
        })
        task.resume()
        
        
    }
}
