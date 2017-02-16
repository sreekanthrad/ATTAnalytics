//
//  ATTScreenViewModel.swift
//  TrackingHelper
//
//  Created by Sreekanth R on 20/01/17.
//  Copyright © 2017 Sreekanth R. All rights reserved.
//

import UIKit
import CoreLocation

class ATTScreenViewModel: NSObject {
    public var screenViewID:String?
    public var screenName:String?
    public var screenViewBeginTime:Date?
    public var previousScreenName:String?
    public var screeViewDuration:Double?
    public var screenEventsArray:Array<AnyObject>?
    public var latitude:CLLocationDegrees?
    public var longitude:CLLocationDegrees?
    
    override init() {
        super.init()
    }
    
    convenience init(screenViewID:String?,
                     screenName name:String?,
                     screenViewBeginAt screenViewBeginTime:Date?,
                     latitude lat:CLLocationDegrees?,
                     longitude log:CLLocationDegrees?) {
        self.init()
        
        self.screenViewID = screenViewID
        self.screenName = name
        self.screenViewBeginTime = screenViewBeginTime
        self.latitude = lat
        self.longitude = log
    }
}
