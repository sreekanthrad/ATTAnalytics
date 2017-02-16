//
//  ATTFlushManager.swift
//  TrackingHelper
//
//  Created by Sreekanth R on 20/01/17.
//  Copyright © 2017 Sreekanth R. All rights reserved.
//

import UIKit

protocol ATTFlushManagerDelegate{
    func flushData() -> Array<AnyObject>?
    func removedSyncedObjects(screenIDArray:Array<String>?) -> Void
}

class ATTFlushManager: NSObject {
    var delegate:ATTFlushManagerDelegate?
    
    // MARK: - deinit
    deinit {
        self.delegate = nil
    }
    
    // MARK: - inits
    override init() {
        super.init()
    }
    
    convenience init(flushInterval:Double?, delegate:ATTFlushManagerDelegate?) {
        self.init()
        self.delegate = delegate
        Timer.scheduledTimer(timeInterval:5,
                             target:self,
                             selector:#selector(ATTFlushManager.flushDataInInterval),
                             userInfo:nil,
                             repeats:true)
    }
    
    // MARK: - End point of Syncing
    // API calls and response handling
    func flushDataInInterval() -> Void {
        let flushableData = self.delegate?.flushData() as Array<AnyObject>?
        if flushableData != nil {
            let schema = self.formattedSchemaFromArray(eventsArray: flushableData)
            if schema != nil {
                let requestPath = "saveAnalyticData"
                let request = ContainerRequest(requestURL:requestPath,
                                               requestParams:schema as Dictionary<String, AnyObject>?,
                                               requestPriority: .Normal)
                Container.container.post(containerRequest: request, onCompletion: { (response) in
                    let responseDict = response?.responseDictionary
                    if responseDict != nil {
                        let syncedKeysArray = responseDict?["syncedObjects"] as? Array<AnyObject>
                        var screenViewIDArray = Array<String>()
                        for eachKeyDict in syncedKeysArray! {
                            screenViewIDArray.append(eachKeyDict["screenViewID"] as! String)
                        }
                        
                        self.delegate?.removedSyncedObjects(screenIDArray: screenViewIDArray)
                    }
                })
            }
        }
    }
    
    // MARK: - Formatting the schema
    func formattedSchemaFromArray(eventsArray:Array<AnyObject>?) -> Dictionary<String, AnyObject>? {
        var resultArray = Array<AnyObject>()
        if (eventsArray?.count)! > 0 {
            for screenViewIndex in 0...(eventsArray?.count)! - 1 {
                let eachScreen:ATTScreenViewModel = eventsArray![screenViewIndex] as! ATTScreenViewModel
                var screenEvents = Array<AnyObject>()
                if eachScreen.screenEventsArray != nil && (eachScreen.screenEventsArray?.count)! > 0 {
                    for eventsIndex in 0...(eachScreen.screenEventsArray?.count)! - 1 {
                        let eachEvent:ATTEventModel = eachScreen.screenEventsArray?[eventsIndex] as! ATTEventModel
                        
                        let eType = (eachEvent.eventType != nil) ? eachEvent.eventType : ""
                        let eName = (eachEvent.eventName != nil) ? eachEvent.eventName : ""
                        let dURL = (eachEvent.dataURL != nil) ? eachEvent.dataURL : ""
                        let eStrtTim = (eachEvent.eventStartTime != nil) ? eachEvent.eventStartTime : Date()
                        let eStrtTimFormated = (eStrtTim?.timeIntervalSince1970)! * 1000
                        let eDur = (eachEvent.eventDuration != nil) ? eachEvent.eventDuration : 0
                        let lat = (eachEvent.latitude != nil) ? eachEvent.latitude : 0
                        let log = (eachEvent.longitude != nil) ? eachEvent.longitude : 0
                        let location = ["latitude":"\(lat!)", "longitude":"\(log!)"]
                        let customParam = (eachEvent.arguments != nil) ? eachEvent.arguments : Dictionary<String, AnyObject>()
                        
                        let eventDictionary = ["eventType":(eType as AnyObject?)!,
                                               "dataURL":(dURL as AnyObject?)!,
                                               "eventName":(eName as AnyObject?)!,
                                               "eventStartTime":("\(eStrtTimFormated)" as AnyObject?)!,
                                               "eventDuration":("\(eDur!)" as AnyObject?)!,
                                               "location":location as AnyObject,
                                               "customParam":customParam as AnyObject] as [String : AnyObject]
                        
                        screenEvents.append(eventDictionary as AnyObject)
                    }
                }
                
                let sID = (eachScreen.screenViewID != nil) ? eachScreen.screenViewID : ""
                let sName = (eachScreen.screenName != nil) ? eachScreen.screenName : ""
                let sPName = (eachScreen.previousScreenName != nil) ? eachScreen.previousScreenName : ""
                let sBTime = (eachScreen.screenViewBeginTime != nil) ? eachScreen.screenViewBeginTime : Date()
                let sBTimeFormted = (sBTime?.timeIntervalSince1970)! * 1000
                let sVDur = (eachScreen.screeViewDuration != nil) ? eachScreen.screeViewDuration : 0
                let lat = (eachScreen.latitude != nil) ? eachScreen.latitude : 0
                let log = (eachScreen.longitude != nil) ? eachScreen.longitude : 0
                let location = ["latitude":"\(lat!)", "longitude":"\(log!)"]
                
                let screenViewDictionary:Dictionary<String, AnyObject> = ["screenViewID":(sID as AnyObject?)!,
                                                                          "presentScreen":(sName as AnyObject?)!,
                                                                          "previousScreen":(sPName as AnyObject?)!,
                                                                          "screenWatchedTime":("\(sBTimeFormted)" as AnyObject?)!,
                                                                          "screenWatchDuration":("\(sVDur!)" as AnyObject?)!,
                                                                          "onScreenActions":screenEvents as AnyObject,
                                                                          "location":location as AnyObject]
                
                resultArray.append(screenViewDictionary as AnyObject)
            }
            
            let baseInfo = ["libInfo":self.libInfo() as AnyObject,
                            "appInfo":self.appInfo() as AnyObject,
                            "deviceInfo":self.deviceInfo() as AnyObject]
            
            let schema = ["baseInfo":baseInfo as AnyObject,
                          "screenViews":resultArray] as [String : Any]
            
            return schema as Dictionary<String, AnyObject>?
        }
       
        return nil
    }
    
    private func appInfo() -> Dictionary<String, AnyObject>? {
        let dictionary = Bundle.main.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String
        let appName = dictionary?["CFBundleName"] as? String
        let bundleID = Bundle.main.bundleIdentifier
        
        var appInfoDictionary = [String: AnyObject]()
        
        appInfoDictionary["bundleVersion"] = version as AnyObject?
        appInfoDictionary["bundleID"] = bundleID as AnyObject?
        appInfoDictionary["bundleName"] = appName as AnyObject?
        
        return appInfoDictionary
    }
    
    private func libInfo() -> Dictionary<String, String>? {
        return ["libVersion":"0.0.1"]
    }
    
    private func deviceInfo() -> Dictionary<String, AnyObject>? {
        var appInfoDictionary = [String: AnyObject]()
        
        appInfoDictionary["deviceID"] = UIDevice.current.identifierForVendor!.uuidString as AnyObject?
        appInfoDictionary["platform"] = "iOS" as AnyObject?
        appInfoDictionary["version"] = UIDevice.current.systemVersion as AnyObject?
        
        return appInfoDictionary
    }
}
