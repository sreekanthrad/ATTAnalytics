//
//  ATTEventModel.swift
//  TrackingHelper
//
//  Created by Sreekanth R on 20/01/17.
//  Copyright © 2017 Sreekanth R. All rights reserved.
//

import UIKit
import CoreLocation

class ATTEventModel: NSObject {
    public var screenViewID:String?
    public var eventType:String?
    public var eventName:String?
    public var eventStartTime:Date?
    public var eventDuration:Double?
    public var dataURL:String?
    public var arguments:Dictionary<String, AnyObject>?
    public var latitude:CLLocationDegrees?
    public var longitude:CLLocationDegrees?
    
    override init() {
        super.init()
    }
    
    convenience init(screenViewID:String?,
                     eventType type:String?,
                     eventName name:String?,
                     eventStartTime startTime:Date?,
                     eventDuration:Double?,
                     latitude lat:CLLocationDegrees?,
                     longitude log:CLLocationDegrees?) {
        self.init()
        
        self.screenViewID = screenViewID
        self.eventType = type
        self.eventName = name
        self.eventStartTime = startTime
        self.eventDuration = eventDuration
        self.latitude = lat
        self.longitude = log
    }
    
    convenience init(screenViewID:String?,
                     eventType type:String?,
                     eventName name:String?,
                     eventStartTime startTime:Date?,
                     eventDuration:Double?,
                     latitude lat:CLLocationDegrees?,
                     longitude log:CLLocationDegrees?,
                     dataURL url:String?,
                     customArguments arguments:Dictionary<String, AnyObject>?) {
        self.init()
        
        self.screenViewID = screenViewID
        self.eventType = type
        self.eventName = name
        self.eventStartTime = startTime
        self.eventDuration = eventDuration
        self.latitude = lat
        self.longitude = log
        self.dataURL = url
        self.arguments = arguments
    }
}
