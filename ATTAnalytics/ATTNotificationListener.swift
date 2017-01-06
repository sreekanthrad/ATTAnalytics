//
//  ATTNotificationListener.swift
//  TrackingHelper
//
//  Created by Sreekanth R on 22/12/16.
//  Copyright © 2016 Sreekanth R. All rights reserved.
//

import UIKit

class ATTNotificationListener: NSObject {
    // MARK: dinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Constructors
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ATTNotificationListener.trackAnEvent(notification:)),
                                               name: NSNotification.Name(rawValue: ATTAnalytics.TrackingNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ATTNotificationListener.trackACrash(notification:)),
                                               name: NSNotification.Name(rawValue: ATTAnalytics.CrashTrackingNotification),
                                               object: nil)
    }
    
    // MARK: Notification listeners
    @objc private func trackAnEvent(notification:NSNotification?) -> Void {
        if notification != nil {
            let dict = notification!.object as! Dictionary<String, AnyObject>
            let configurations = dict["configuration"] as? Array<AnyObject>
            
            if configurations != nil && configurations!.count > 0 {
                for eachConfig in configurations! {
                    let agentName = eachConfig[ATTConfigConstants.AgentName] as? String
                    let cleanString = self.hiphenRemovedLowercaseString(aString: agentName)
                    
                    if cleanString == ATTConfigConstants.GoogleAnalytics {
                        if NSClassFromString("GAIHelper") != nil {
                            print("First log ======")
                            let aClass = NSClassFromString("GAIHelper") as! NSObject.Type
                            let gaHelper = aClass.init()
                            
                            gaHelper.perform(NSSelectorFromString("beginTrackingGAConfigurationsWithConfigurations:"),
                                             with: eachConfig as? Dictionary<String, AnyObject>)
                        }
                    }
                    
                    if cleanString == ATTConfigConstants.FirebaseAnalytics {
                        
                    }
                }
            }            
        }
    }
    
    @objc private func trackACrash(notification:NSNotification?) -> Void {
        if notification != nil {
            let dict = notification!.object as! NSDictionary
            print(dict)
        }
    }
    
    private func hiphenRemovedLowercaseString(aString:String?) -> String? {
        if aString != nil {
            let strippedString = aString?.replacingOccurrences(of: "_", with: "")
            return strippedString?.replacingOccurrences(of: "-", with: "").lowercased()
        }
        
        return nil
    }
}
