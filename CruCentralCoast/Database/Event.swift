//
//  Event.swift
//  CruCentralCoast
//
//  Created by Cam Stocker on 5/2/18.
//  Copyright © 2018 Landon Gerrits. All rights reserved.
//

import Foundation
import Firebase

class Event: NSObject, DatabaseObject {
    var title: String
    var startDate: Date
    var endDate: Date
    var summary: String
    var locationDict : NSDictionary
    var location: String = ""
    var imageLink: String
    var facebookURL: String
    @objc dynamic var image: UIImage?
    
    required init?(dict: NSDictionary) {
        guard let title = dict["name"] as? String,
            let summary = dict["description"] as? String,
            let startDate = dict["startDate"] as? Date,
            let endDate = dict["endDate"] as? Date,
            let locationDict = dict["location"] as? NSDictionary,
            let imageLink = dict["imageLink"] as? String,
            let facebookURL = dict["url"] as? String
        else {
            return nil
        }
        self.title = title
        self.summary = summary
        self.startDate = startDate
        self.imageLink = imageLink
        self.endDate = endDate
        self.locationDict = locationDict
        self.facebookURL = facebookURL
        
        guard let street = locationDict.value(forKey: "street1") as? String
        else {
            return nil
        }
        
        self.location = self.location + street
        
        super.init()
    }
}
