//
//  TrackingHelper.swift
//  test
//
//  Created by Sreekanth R on 03/11/16.
//  Copyright © 2016 Sreekanth R. All rights reserved.
//

import Foundation
import UIKit

public class ATTAnalytics: NSObject {
    
    // MARK: Public members
    // MARK: Pubclic Constants
    public static let TrackingNotification = "RegisterForTrakingNotification"
    public static let CrashTrackingNotification = "RegisterForCrashTrakingNotification"
    
    // For Objective - C support since the converted framework not supporting swift enums
    public static let TrackingTypeAuto = "Auto"
    public static let TrackingTypeManual = "Manual"
    
    // MARK: Enums
    public enum TrackingTypes {
        case Automatic
        case Manual
    }
    
    // MARK: Private members
    enum StateTypes {
        case State
        case Event
    }
    
    private var configParser:ATTConfigParser?
    private var configurationFilePath:String?
    private var stateChangeTrackingSelector:Selector?
    private let cacheDirectory = (NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                      .userDomainMask,
                                                                      true)[0] as String).appending("/")
    // MARK: Lazy variables
    lazy var fileManager: FileManager = {
        return FileManager.default
    }()
    
    // MARK: Shared object
    /// Shared Object
    public class var helper: ATTAnalytics {
        struct Static {
            static let instance = ATTAnalytics()
        }
        return Static.instance
    }
    
    // MARK: deinit
    deinit {
        self.configParser = nil
        self.configurationFilePath = nil
        self.stateChangeTrackingSelector = nil
    }
    
    // MARK: Public Methods
    // Method with Local resource path
    public func beginTracking(pathForConfigFile:String?) -> Void {
        self.beginTracking(pathForConfigFile:pathForConfigFile, stateTrackingType:.Manual, methodTrackingType:.Manual)
    }
    
    public func beginTracking(pathForConfigFile:String?,
                              stateTrackingType stateType:TrackingTypes?,
                              methodTrackingType methodType:TrackingTypes?) -> Void {
        
        self.configurationFilePath = pathForConfigFile
        self.createConfigParser(configurations:self.configurationDictionary() as? Dictionary<String, AnyObject>)
        self.configureSwizzling(stateTracking:stateType, methodTracking:methodType)
    }

    // Method with configurations as Dictionary
    public func beginTracking(configuration:Dictionary<String, AnyObject>?) -> Void {
        self.beginTracking(configuration:configuration, stateTrackingType:.Manual, methodTrackingType:.Manual)
    }
    
    public func beginTracking(configuration:Dictionary<String, AnyObject>?,
                              stateTrackingType stateType:TrackingTypes?,
                              methodTrackingType methodType:TrackingTypes?) -> Void {
        
        self.createConfigParser(configurations:configuration)
        self.configureSwizzling(stateTracking:stateType, methodTracking:methodType)
    }
    
    // Support of Objective - C
    // Swift project not required the below function calls
    public func beginTracking(pathForConfigFile:String?,
                              stateTrackingType stateType:String?,
                              methodTrackingType methodType:String?) -> Void {
        
        self.configurationFilePath = pathForConfigFile
        self.createConfigParser(configurations:self.configurationDictionary() as? Dictionary<String, AnyObject>)
        self.configureObjCEventTracking(stateTrackingType: stateType, methodTrackingType: methodType)
    }
    
    public func beginTracking(configuration:Dictionary<String, AnyObject>?,
                              stateTrackingType stateType:String?,
                              methodTrackingType methodType:String?) -> Void {
        
        self.createConfigParser(configurations:configuration)
        self.configureObjCEventTracking(stateTrackingType: stateType, methodTrackingType: methodType)
    }
    
    /// Can be called manually for Manual event tracking
    /// **customArguments** is used when an object requires to trigger event with dynamic values
    public func registerForTracking(appSpecificKeyword keyword:String?,
                                    customArguments arguments:Dictionary<String, AnyObject>?) -> Void {
        
        self.trackConfigurationForClass(aClass:nil,
                                        withSelector:nil,
                                        ofStateType:.Event,
                                        havingAppSpecificKeyword:keyword,
                                        withCustomArguments:arguments)
    }
    
    /// Used to receive the crashlog events
    /// Must be called once inside AppDelegate's **applicationDidBecomeActive**
    public func registerForCrashLogging() -> Void {
        if let crashLogData = self.readLastSavedCrashLog() {
            
            if (crashLogData as String).characters.count > 0 {
                var notificationObject = [String: AnyObject]()
                
                notificationObject["type"] = "CrashLogTracking" as AnyObject?
                notificationObject["crash_report"] = crashLogData as AnyObject?
                notificationObject["app_info"] = self.appInfo() as AnyObject?
                
                NotificationCenter.default.post(name:NSNotification.Name(rawValue:ATTAnalytics.CrashTrackingNotification),
                                                object:notificationObject)
            }
        }
    }
    
    // MARK: Private methods
    private func configureObjCEventTracking(stateTrackingType stateType:String?,
                                            methodTrackingType methodType:String?) -> Void {
        var sType:TrackingTypes = .Manual
        var mType:TrackingTypes = .Manual
        if stateType == ATTAnalytics.TrackingTypeAuto {
            sType = .Automatic
        }
        
        if methodType == ATTAnalytics.TrackingTypeAuto {
            mType = .Automatic
        }
        
        self.configureSwizzling(stateTracking:sType, methodTracking:mType)
    }
    
    private func createConfigParser(configurations:Dictionary<String, AnyObject>?) -> Void{
        self.configParser = nil
        self.configParser = ATTConfigParser(configurations:configurations)
    }
    
    private func configureSwizzling(stateTracking state:TrackingTypes?,
                                    methodTracking method:TrackingTypes?) -> Void {        
        if state == .Automatic {
            self.swizzileLifecycleMethodImplementation()
        }
        
        if method == .Automatic {
            self.swizzileCustomMethods()
        }
    }
    
    // Triggered for state changes
    private func triggerEventForTheVisibleViewController(viewController:UIViewController) -> Void {
        self.trackConfigurationForClass(aClass:viewController.classForCoder,
                                        withSelector:self.stateChangeTrackingSelector,
                                        ofStateType:.State,
                                        havingAppSpecificKeyword:nil,
                                        withCustomArguments:nil)
    }
    
    // Triggered for method invocation
    private func triggerEventForTheVisibleViewController(originalClass:AnyClass?, selector:Selector?) -> Void {
        self.trackConfigurationForClass(aClass:originalClass,
                                        withSelector:selector,
                                        ofStateType:.Event,
                                        havingAppSpecificKeyword:nil,
                                        withCustomArguments:nil)
    }
    
    // Looping through the configuration to find out the matching paramters and values
    private func trackConfigurationForClass(aClass:AnyClass?,
                                            withSelector selector:Selector?,
                                            ofStateType type:StateTypes?,
                                            havingAppSpecificKeyword keyword:String?,
                                            withCustomArguments arguments:Dictionary<String, AnyObject>?) -> Void {
        
        let paramters = self.configurationForClass(aClass:aClass,
                                                   withSelector:selector,
                                                   ofStateType:type,
                                                   havingAppSpecificKeyword:keyword)
        
        if paramters != nil && (paramters?.count)! > 0 {
            self.registeredAnEvent(configuration:paramters,
                                   customArguments:arguments)
        }
    }
    
    // Parsing the Configuration file
    private func configurationDictionary() -> NSDictionary? {
        let resourcePath = self.configurationFilePath
        var resourceData:NSDictionary?
            
        if resourcePath != nil {
            resourceData = NSDictionary(contentsOfFile: resourcePath!)
        } else {
            print("Could not find the configuration file at the given path!")
        }
        
        return resourceData
    }
    
    private func configurationForClass(aClass:AnyClass?,
                                       withSelector selector:Selector?,
                                       ofStateType type:StateTypes?,
                                       havingAppSpecificKeyword keyword:String?) -> Array<AnyObject>? {
        var state = ""
        if type == .State {
            state = ATTConfigConstants.AgentKeyTypeState
        } else {
            state = ATTConfigConstants.AgentKeyTypeEvent
        }
        
        let resultConfig = (self.configParser?.findConfigurationForClass(aClass:aClass,
                                                                         withSelector:selector,
                                                                         ofStateType:state,
                                                                         havingAppSpecificKeyword:keyword))! as Array<AnyObject>
        return resultConfig
    }
    
    // Triggering a Notification, whenever it finds a matching configuration
    private func registeredAnEvent(configuration:Array<AnyObject>?,
                                   customArguments:Dictionary<String, AnyObject>?) -> Void {
        
        var notificationObject = [String: AnyObject]()

        notificationObject["configuration"] = configuration as AnyObject?
        notificationObject["custom_arguments"] = customArguments as AnyObject?
        notificationObject["app_info"] = self.appInfo() as AnyObject?
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue:ATTAnalytics.TrackingNotification),
                                        object:notificationObject)
    }
    
    private func appInfo() -> Dictionary<String, AnyObject>? {
        let dictionary = Bundle.main.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String
        let build = dictionary?["CFBundleVersion"] as? String
        let appName = dictionary?["CFBundleName"] as? String
        let bundleID = Bundle.main.bundleIdentifier
        
        var appInfoDictionary = [String: AnyObject]()
        
        appInfoDictionary["version"] = version as AnyObject?
        appInfoDictionary["build"] = build as AnyObject?
        appInfoDictionary["bundleID"] = bundleID as AnyObject?
        appInfoDictionary["app_name"] = appName as AnyObject?
        
        return appInfoDictionary
    }
    
    // MARK: Crashlog file manipulations
    private func readLastSavedCrashLog() -> String? {
        let fileName = self.fileNameForLogFileOn(onDate:Date())
        let filePath = self.cacheDirectory.appending(fileName!)
        var dataString:String = String()
        
        self.clearYesterdaysCrashLog()
        
        if self.fileManager.fileExists(atPath:filePath) {
            if let crashLogData = NSData(contentsOfFile:filePath) {
                dataString = NSString(data:crashLogData as Data, encoding:String.Encoding.utf8.rawValue) as! String
            }
        }
        
        // To avoid complexity in reading and parsing the crash log, keeping only the last crash information
        // For allowing this, previous crash logs are deleted after reading
        self.removeCrashLogOn(onDate:Date())
        self.createCrashLogFile(atPath:filePath)
        return dataString
    }
    
    // Log files are being created with current date as its name
    // In odrder to prevent dumping of logs, will be removing previous log files
    // Date is used in order to extend the feature of multiple crash logs
    private func clearYesterdaysCrashLog() -> Void {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding:.day, value:-1, to:Date())
        
        self.removeCrashLogOn(onDate: yesterday)
    }
    
    private func createCrashLogFile(atPath: String) -> Void {
        freopen(atPath.cString(using:String.Encoding.utf8), "a+", stderr)
    }
    
    private func removeCrashLogOn(onDate: Date?) -> Void {
        let filePath = self.cacheDirectory.appending(self.fileNameForLogFileOn(onDate:onDate)!)
        try?self.fileManager.removeItem(atPath:filePath)
    }
    
    private func fileNameForLogFileOn(onDate:Date?) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        
        return "CrashlogAsOn-".appending(formatter.string(from:onDate!).appending(".log"))
    }
    
    // MARK: Automatic screen change tracking
    // MUST BE CALLED ONLY ONCE
    private func swizzileLifecycleMethodImplementation() -> Void {
        let originalClass = UIViewController.self
        let swizzilableClass = ATTAnalytics.self
        let swizzilableSelector = #selector(ATTAnalytics.trackScreenChange(_:))        
        self.stateChangeTrackingSelector = #selector(UIViewController.viewDidAppear(_:))
        
        let originalMethod = class_getInstanceMethod(originalClass, self.stateChangeTrackingSelector!)
        let swizzledMethod = class_getInstanceMethod(swizzilableClass, swizzilableSelector)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // Swizzled method which will be replacing the original ViewController methods which is mentioned in the autoScreenTrackingType
    func trackScreenChange(_ animated: Bool) -> Void {
        // Here self refers to the UIViewController, self.autoTrackScreenChanges() will crash
        if "\(self.classForCoder)" != "UINavigationController"
            && "\(self.classForCoder)" != "UITabBarController"
            && "\(self.classForCoder)" != "UIInputWindowController" {
            
            ATTAnalytics.helper.autoTrackScreenChanges(viewController: self)
        }
    }
    
    func autoTrackScreenChanges(viewController:NSObject?) -> Void {
        if let topViewController = viewController as? UIViewController {
            self.triggerEventForTheVisibleViewController(viewController:topViewController)
        }
    }
    
    // MARK: Automatic function call tracking
    // MUST BE CALLED ONLY ONCE
    private func swizzileCustomMethods() -> Void {
        let originalClass:AnyClass = UIApplication.self
        let swizzilableClass = ATTAnalytics.self
        
        let originalMethod = class_getInstanceMethod(originalClass,
                                                     #selector(UIApplication.sendAction(_:to:from:for:)))
        let swizzledMethod = class_getInstanceMethod(swizzilableClass,
                                                     #selector(ATTAnalytics.trackIBActionInvocation(_:to:from:for:)))
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // Swizzled method which will be replacing the original UIApplication's sendAction method
    func trackIBActionInvocation(_ action:Selector, to target:Any?, from sender:Any?, for event:UIEvent?) -> Void {
        if let originalObject = target as? NSObject {
            let originalClass:AnyClass = originalObject.classForCoder as AnyClass
            ATTAnalytics.helper.autoTrackMethodInvocationForClass(originalClass:originalClass, selector:action)
        }
        
        // Inorder to call the original implementation, perform the 3 below steps
        ATTAnalytics.helper.swizzileCustomMethods()
        UIApplication.shared.sendAction(action, to:target, from:sender, for:event)
        ATTAnalytics.helper.swizzileCustomMethods()
    }
    
    func autoTrackMethodInvocationForClass(originalClass:AnyClass?, selector:Selector?) -> Void {
        self.triggerEventForTheVisibleViewController(originalClass:originalClass, selector:selector)
    }
}


