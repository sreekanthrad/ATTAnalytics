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
    
    private static let crashLogFileName = "ATTCrashLog.log"
    
    private var configParser:ATTConfigParser?    
    
    private var configurationFilePath:String?
    private var presentViewControllerName:String?
    private var previousViewControllerName:String?
    private var screenViewID:String?
    private var stateChangeTrackingSelector:Selector?
    private var screenViewStart:Date?
    private var previousScreenViewStart:Date?
    private var screenViewEnd:Date?
    private var screenViewDuration:Double?
    private let cacheDirectory = (NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                      .userDomainMask,
                                                                      true)[0] as String).appending("/")
    // MARK: - Lazy variables
    lazy var fileManager: FileManager = {
        return FileManager.default
    }()
    
    lazy var schemaManager: ATTMiddlewareSchemaManager = {
        return ATTMiddlewareSchemaManager()
    }()
    
    // MARK: - Shared object
    /// Shared Object
    public class var helper: ATTAnalytics {
        struct Static {
            static let instance = ATTAnalytics()
        }
        
        return Static.instance
    }
    
    // MARK: - deinit
    deinit {
        self.configParser = nil
        self.configurationFilePath = nil
        self.stateChangeTrackingSelector = nil
        self.screenViewStart = nil
        self.screenViewEnd = nil
        self.presentViewControllerName = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    // Method with Local resource path
    public func beginTracking(pathForConfigFile:String?) -> Void {
        self.beginTracking(pathForConfigFile:pathForConfigFile, stateTrackingType:.Manual, actionTrackingType:.Manual)
    }
    
    public func beginTracking(pathForConfigFile:String?,
                              stateTrackingType stateType:TrackingTypes?,
                              actionTrackingType methodType:TrackingTypes?) -> Void {
        
        self.configurationFilePath = pathForConfigFile
        self.createConfigParser(configurations:self.configurationDictionary() as? Dictionary<String, AnyObject>)
        self.configureSwizzling(stateTracking:stateType, methodTracking:methodType)
        self.setupMiddlewareManager()
    }

    // Method with configurations as Dictionary
    public func beginTracking(configuration:Dictionary<String, AnyObject>?) -> Void {
        self.beginTracking(configuration:configuration, stateTrackingType:.Manual, actionTrackingType:.Manual)
    }
    
    public func beginTracking(configuration:Dictionary<String, AnyObject>?,
                              stateTrackingType stateType:TrackingTypes?,
                              actionTrackingType methodType:TrackingTypes?) -> Void {
        
        self.createConfigParser(configurations:configuration)
        self.configureSwizzling(stateTracking:stateType, methodTracking:methodType)
        self.setupMiddlewareManager()
    }
    
    // Support of Objective - C
    // Swift project not required the below function calls
    public func beginTracking(pathForConfigFile:String?,
                              stateTrackingType stateType:String?,
                              actionTrackingType methodType:String?) -> Void {
        
        self.configurationFilePath = pathForConfigFile
        self.createConfigParser(configurations:self.configurationDictionary() as? Dictionary<String, AnyObject>)
        self.configureObjCEventTracking(stateTrackingType: stateType, actionTrackingType: methodType)
        self.setupMiddlewareManager()
    }
    
    public func beginTracking(configuration:Dictionary<String, AnyObject>?,
                              stateTrackingType stateType:String?,
                              actionTrackingType methodType:String?) -> Void {
        
        self.createConfigParser(configurations:configuration)
        self.configureObjCEventTracking(stateTrackingType: stateType, actionTrackingType: methodType)
        self.setupMiddlewareManager()
    }
    
    /// Can be called manually for Manual event tracking
    /// **customArguments** is used when an object requires to trigger event with dynamic values
    public func registerForTracking(appSpecificKeyword keyword:String?,
                                    dataURL url:String?,
                                    customArguments arguments:Dictionary<String, AnyObject>?,
                                    customEvent event:ATTCustomEvent?) -> Void {
        
        let configs = self.trackConfigurationForClass(aClass:nil,
                                                      withSelector:nil,
                                                      ofStateType:.Event,
                                                      havingAppSpecificKeyword:keyword,
                                                      withCustomArguments:arguments)
        var eventArguments = arguments
        var duration:Double = 0.0
        if event != nil {
            duration = (event?.duration)!
        }
        
        if configs != nil {
            var customParams = Array<AnyObject>()
            for eachParam in configs! {
                let customParamDict = ["agent":eachParam["agent"] as AnyObject,
                                       "param":eachParam["param"] as AnyObject]
                customParams.append(customParamDict as AnyObject)
            }
            
            eventArguments?["AgentParams"] = customParams as AnyObject            
        }
        
        ATTMiddlewareSchemaManager.manager.createCustomEvent(eventName: keyword,
                                                             eventStartTime: Date(),
                                                             dataURL: url,
                                                             customArguments: eventArguments,
                                                             eventDuration: duration)
    }
    
    /// Used to receive the crashlog events
    /// Must be called once inside AppDelegate's **applicationDidBecomeActive**
    public func registerForCrashLogging() -> Void {
        if let crashLogData = self.readLastSavedCrashLog() {
            
            if (crashLogData as String).characters.count > 0 {
                var notificationObject = [String: AnyObject]()
                
                notificationObject["type"]          = "CrashLogTracking" as AnyObject?
                notificationObject["crash_report"]  = crashLogData as AnyObject?
                notificationObject["app_info"]      = self.appInfo() as AnyObject?
                
                NotificationCenter.default.post(name:NSNotification.Name(rawValue:ATTAnalytics.CrashTrackingNotification),
                                                object:notificationObject)
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Private methods
    private func setupMiddlewareManager() -> Void {
        ATTMiddlewareSchemaManager.manager.startUpdatingLocations()
        ATTMiddlewareSchemaManager.manager.startFlushManager()
        ATTMiddlewareSchemaManager.manager.appInfo = self.appInfo()
    }
    
    private func configureObjCEventTracking(stateTrackingType stateType:String?,
                                            actionTrackingType methodType:String?) -> Void {
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
            self.swizzileIBActionMethods()
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
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
    @discardableResult private func trackConfigurationForClass(aClass:AnyClass?,
                                            withSelector selector:Selector?,
                                            ofStateType type:StateTypes?,
                                            havingAppSpecificKeyword keyword:String?,
                                            withCustomArguments arguments:Dictionary<String, AnyObject>?) -> Array<AnyObject>? {
        
        let paramters = self.configurationForClass(aClass:aClass,
                                                   withSelector:selector,
                                                   ofStateType:type,
                                                   havingAppSpecificKeyword:keyword)
        
        if paramters != nil && (paramters?.count)! > 0 {
            self.registeredAnEvent(configuration:paramters,
                                   customArguments:arguments)
        }
        
        return paramters
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

        notificationObject["configuration"]     = configuration as AnyObject?
        notificationObject["custom_arguments"]  = customArguments as AnyObject?
        notificationObject["app_info"]          = self.appInfo() as AnyObject?
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue:ATTAnalytics.TrackingNotification),
                                        object:notificationObject)
    }
    
    private func appInfo() -> Dictionary<String, AnyObject>? {
        let dictionary  = Bundle.main.infoDictionary
        let version     = dictionary?["CFBundleShortVersionString"] as? String
        let build       = dictionary?["CFBundleVersion"] as? String
        let appName     = dictionary?["CFBundleName"] as? String
        let bundleID    = Bundle.main.bundleIdentifier
        
        var appInfoDictionary = [String: AnyObject]()
        
        appInfoDictionary["build"]          = build as AnyObject?
        appInfoDictionary["bundleVersion"]  = version as AnyObject?
        appInfoDictionary["bundleID"]       = bundleID as AnyObject?
        appInfoDictionary["bundleName"]     = appName as AnyObject?
        
        return appInfoDictionary
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Crashlog file manipulations
    private func readLastSavedCrashLog() -> String? {
        let fileName = ATTAnalytics.crashLogFileName
        let filePath = self.cacheDirectory.appending(fileName)
        var dataString:String = String()
        
        if self.fileManager.fileExists(atPath:filePath) {
            if let crashLogData = NSData(contentsOfFile:filePath) {
                dataString = NSString(data:crashLogData as Data, encoding:String.Encoding.utf8.rawValue) as! String
            }
        }
        
        // To avoid complexity in reading and parsing the crash log, keeping only the last crash information
        // For allowing this, previous crash logs are deleted after reading
        self.removeLastSavedCrashLog()
        self.createCrashLogFile(atPath:filePath)
        return dataString
    }
    
    private func createCrashLogFile(atPath: String) -> Void {
        freopen(atPath.cString(using:String.Encoding.utf8), "a+", stderr)
    }
    
    private func removeLastSavedCrashLog() -> Void {
        let filePath = self.cacheDirectory.appending(ATTAnalytics.crashLogFileName)
        try?self.fileManager.removeItem(atPath:filePath)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Automatic screen change tracking
    // MUST BE CALLED ONLY ONCE
    private func swizzileLifecycleMethodImplementation() -> Void {
        let originalClass = UIViewController.self
        let swizzilableClass = ATTAnalytics.self
        
        self.swizzileViewWillAppear(originalClass: originalClass, and: swizzilableClass)
        self.swizzileViewDidDisappear(originalClass: originalClass, and: swizzilableClass)
        // WillAppear and DidDisappear is done to track maximum events
    }
    
    private func swizzileViewWillAppear(originalClass:AnyClass?, and swizzilableClass:AnyClass?) -> Void {
        let swizzilableSelector = #selector(ATTAnalytics.trackViewWillAppear(_:))
        self.stateChangeTrackingSelector = #selector(UIViewController.viewWillAppear(_:))
        
        let originalMethod = class_getInstanceMethod(originalClass, self.stateChangeTrackingSelector!)
        let swizzledMethod = class_getInstanceMethod(swizzilableClass, swizzilableSelector)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    private func swizzileViewDidDisappear(originalClass:AnyClass?, and swizzilableClass:AnyClass?) -> Void {
        let swizzilableSelector = #selector(ATTAnalytics.trackViewDidDisappear(_:))
        let originalSelector = #selector(UIViewController.viewDidDisappear(_:))
        
        let originalMethod = class_getInstanceMethod(originalClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(swizzilableClass, swizzilableSelector)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // Swizzled methods
    func trackViewWillAppear(_ animated: Bool) -> Void {
        // Here self refers to the UIViewController, self.autoTrackScreenChanges() will crash
        if "\(self.classForCoder)" != "UINavigationController"
            && "\(self.classForCoder)" != "UITabBarController"
            && "\(self.classForCoder)" != "UIInputWindowController" {
            
            ATTAnalytics.helper.autoTrackScreenChanges(viewController: self)
        }
    }
    
    func trackViewDidDisappear(_ animated: Bool) -> Void {
        // Here self refers to the UIViewController, self.autoTrackScreenChanges() will crash
        if "\(self.classForCoder)" != "UINavigationController"
            && "\(self.classForCoder)" != "UITabBarController"
            && "\(self.classForCoder)" != "UIInputWindowController" {
            
            ATTAnalytics.helper.presentScreenDisappeared(viewController: self)
        }
    }
    
    func autoTrackScreenChanges(viewController:NSObject?) -> Void {
        if let topViewController = viewController as? UIViewController {
            self.presentViewControllerName = "\(topViewController.classForCoder)"
            self.screenViewStart = Date()
            self.triggerEventForTheVisibleViewController(viewController:topViewController)
            self.createNewScreenView(withClass: topViewController.classForCoder)
            self.formulatePreviousScreenActivityObject()
        }
    }
    
    func presentScreenDisappeared(viewController:NSObject?) -> Void {
        if let topViewController = viewController as? UIViewController {
            if self.presentViewControllerName == "\(topViewController.classForCoder)" {
                self.screenViewEnd = Date()
                self.screenViewDuration = self.screenViewEnd?.timeIntervalSince(self.screenViewStart!)
                self.previousViewControllerName = "\(topViewController.classForCoder)"
                self.previousScreenViewStart = self.screenViewStart
            }
        }
    }
    
    private func createNewScreenView(withClass aClass:AnyClass?) -> Void {
        self.screenViewID = self.schemaManager.newScreenViewID()
        ATTMiddlewareSchemaManager.manager.startNewScreenViewWithScreenID(screenViewID: self.screenViewID,
                                                                          screenName: self.presentViewControllerName,
                                                                          screenClass:aClass,
                                                                          screenViewBeginAt: self.screenViewStart)
    }
    
    private func formulatePreviousScreenActivityObject() -> Void {
        var previousScreen = self.previousViewControllerName
        if previousScreen == nil { previousScreen = "" }
        
        ATTMiddlewareSchemaManager.manager.updateScreenCloseDetails(previousScreen: previousScreen,
                                                                    screenViewDuration: self.screenViewDuration)        
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Automatic function call tracking
    // MUST BE CALLED ONLY ONCE
    private func swizzileIBActionMethods() -> Void {
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
        ATTAnalytics.helper.swizzileIBActionMethods()
        UIApplication.shared.sendAction(action, to:target, from:sender, for:event)
        ATTAnalytics.helper.swizzileIBActionMethods()
    }
    
    func autoTrackMethodInvocationForClass(originalClass:AnyClass?, selector:Selector?) -> Void {
        self.triggerEventForTheVisibleViewController(originalClass:originalClass, selector:selector)
        ATTMiddlewareSchemaManager.manager.createIBActionEvent(eventName: "\(selector!)", eventStartTime: Date())
    }
}


