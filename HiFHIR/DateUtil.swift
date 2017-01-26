//
//  DateUtil.swift
//  HiFHIR
//
//  Created by Igor Bossenko on 26/01/2017.
//  Copyright © 2017 Nortal. All rights reserved.
//

import Foundation

class DateUtil {
    
    class func format(timestamp:String) -> String {
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
