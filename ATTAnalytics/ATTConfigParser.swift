//
//  ATTConfigParser.swift
//  TrackingSampple
//
//  Created by Sreekanth R on 23/11/16.
//  Copyright © 2016 Sreekanth R. All rights reserved.
//
/// Do visit http://www.jsoneditoronline.org/?id=7eabb6c0d615aeef65c40af1bf1c4a4b for config pattern

import UIKit

class ATTConfigParser: NSObject {
    // MARK: - Private members
    var configurations:Dictionary<String, AnyObject>?
    
    // MARK: - deinit
    deinit {
        self.configurations = nil
    }
    
    override init() {
        super.init()
    }
    
    convenience init(configurations:Dictionary<String, AnyObject>?) {
        self.init()
        self.configurations = configurations
    }
    
    // MARK: - Public methods
    func findConfigurationForClass(aClass:AnyClass?,
                                   withSelector selector:Selector?,
                                   ofStateType type:String?,
                                   havingAppSpecificKeyword keyword:String?) -> Array<AnyObject>? {
    
        var resultArray:Array = Array<AnyObject>()
        if self.configurations != nil {
            let root:Array? = self.configurations![ATTConfigConstants.Analytics] as? Array<AnyObject>
            if root != nil {
                for eachAgent in root! {
                    let agentEnabled:Bool = eachAgent[ATTConfigConstants.AgentEnabled] as! Bool
                    if agentEnabled == true {
                        let dataField:Array? = eachAgent[ATTConfigConstants.AgentDataField] as? Array<AnyObject>
                        var resultConfig:Dictionary<String, AnyObject>?
                        
                        if type == ATTConfigConstants.AgentKeyTypeState {
                            resultConfig = self.stateConfigFromDataField(dataField:dataField,
                                                                         agent:eachAgent as? Dictionary<String, AnyObject>,
                                                                         aClass:aClass,
                                                                         selector:selector,
                                                                         appSpecificKeyword:keyword)
                        } else {
                            resultConfig = self.eventConfigFromDataField(dataField:dataField,
                                                                         agent:eachAgent as? Dictionary<String, AnyObject>,
                                                                         aClass:aClass,
                                                                         selector:selector,
                                                                         appSpecificKeyword:keyword)
                        }
                        
                        if resultConfig != nil && resultConfig!.count > 0 {
                            resultArray.append(resultConfig as AnyObject)
                        }
                    }
                }
            }
        }
        
        return resultArray
    }
    
    // MARK: - Private methods
    // Filtering state change configurations
    private func stateConfigFromDataField(dataField:Array<AnyObject>?,
                                          agent:Dictionary<String, AnyObject>?,
                                          aClass:AnyClass?,
                                          selector:Selector?,
                                          appSpecificKeyword:String?) -> Dictionary<String, AnyObject>? {
        
        var resultConfig = Dictionary<String, AnyObject>()
        
        for eachData in dataField! {
            let appSpecificClass = eachData[ATTConfigConstants.AppSpecificClass] as? String
            let keyType:String = eachData[ATTConfigConstants.AgentKeyType] as! String
            
            if keyType == ATTConfigConstants.AgentKeyTypeState {
                if appSpecificClass != nil && aClass != nil && appSpecificClass == "\(aClass!)" {
                    let result = self.appendAgentDetails(agent:agent,
                                                         dataField:eachData as? Dictionary<String, AnyObject>)
                    resultConfig = result!
                    break
                }
            }
        }
        
        return resultConfig
    }
    
    // Filtering event configurations
    private func eventConfigFromDataField(dataField:Array<AnyObject>?,
                                          agent:Dictionary<String, AnyObject>?,
                                          aClass:AnyClass?,
                                          selector:Selector?,
                                          appSpecificKeyword:String?) -> Dictionary<String, AnyObject>? {
        
        var resultConfig:Dictionary<String, AnyObject>?
        
        for eachData in dataField! {
            let appSpecificClass = eachData[ATTConfigConstants.AppSpecificClass] as? String
            let appSpecificMethod = eachData[ATTConfigConstants.AppSpecificMethod] as? String
            let keyType:String = eachData[ATTConfigConstants.AgentKeyType] as! String
            let appSpecificKey = eachData[ATTConfigConstants.AppSpecificKey] as? String
            
            if keyType == ATTConfigConstants.AgentKeyTypeEvent {
                if appSpecificClass != nil
                    && appSpecificMethod != nil
                    && aClass != nil
                    && selector != nil
                    && appSpecificClass == "\(aClass!)"
                    && appSpecificMethod == "\(selector!)"{
                    
                    let result = self.appendAgentDetails(agent:agent,
                                                         dataField:eachData as? Dictionary<String, AnyObject>)
                    resultConfig = result!
                    break
                    
                } else {
                    if appSpecificKey != nil && appSpecificKey == appSpecificKeyword {
                        let result = self.appendAgentDetails(agent:agent,
                                                             dataField:eachData as? Dictionary<String, AnyObject>)
                        resultConfig = result!
                        break
                    }
                }
            }
        }
        
        return resultConfig
    }
    
    private func appendAgentDetails(agent:Dictionary<String, AnyObject>?,
                                    dataField:Dictionary<String, AnyObject>?) -> Dictionary<String, AnyObject>? {
        var resultDict = Dictionary<String, AnyObject>()
        
        resultDict[ATTConfigConstants.AgentName]            = agent?[ATTConfigConstants.AgentName]
        resultDict[ATTConfigConstants.AgentType]            = agent?[ATTConfigConstants.AgentType]
        resultDict[ATTConfigConstants.AgentURL]             = agent?[ATTConfigConstants.AgentURL]
        resultDict[ATTConfigConstants.AgentFlushInterval]   = agent?[ATTConfigConstants.AgentFlushInterval]
        resultDict[ATTConfigConstants.AgentPostToURL]       = agent?[ATTConfigConstants.AgentPostToURL]
        resultDict[ATTConfigConstants.AgentEnabled]         = agent?[ATTConfigConstants.AgentEnabled]
        resultDict[ATTConfigConstants.AgentKey]             = dataField?[ATTConfigConstants.AgentKey]
        resultDict[ATTConfigConstants.AgentKeyType]         = dataField?[ATTConfigConstants.AgentKeyType]
        resultDict[ATTConfigConstants.AppSpecificMethod]    = dataField?[ATTConfigConstants.AppSpecificMethod]
        resultDict[ATTConfigConstants.AppSpecificClass]     = dataField?[ATTConfigConstants.AppSpecificClass]
        resultDict[ATTConfigConstants.AppSpecificKey]       = dataField?[ATTConfigConstants.AppSpecificKey]
        resultDict[ATTConfigConstants.AgentParam]           = dataField?[ATTConfigConstants.AgentParam]
        
        return resultDict
    }
}
