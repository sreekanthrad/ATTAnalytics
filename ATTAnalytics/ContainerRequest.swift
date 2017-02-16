//
//  ContainerRequest.swift
//  Sample
//
//  Created by Sreekanth R on 27/10/16.
//  Copyright © 2016 Sreekanth R. All rights reserved.
//

import Foundation

class ContainerRequest: NSObject {
    static let Get = "GET"
    static let Post = "POST"
    
    // API Response caching mechanism
    enum CachingTypes {
        case DefaultCaching // Default Caching by URLSession
        case InMemoryCaching // Manual Caching done in the document directory
        case NoCaching // Will not cache anything
    }
    
    enum RequestPriority {
        case VeryLow
        case Low
        case Normal
        case High
        case VeryHigh
    }
    
    // MARK: Properties
    var requestURL:String?
    var requestParams:Dictionary<String, AnyObject>?
    
    var cachingPolicy:CachingTypes?
    var priority:RequestPriority?
    
    // MARK: Constructor
    override init() {
        super.init()
    }
    
    convenience init(requestURL:String?, requestPriority:RequestPriority?) {
        self.init()
        
        self.requestURL = requestURL
        self.priority = requestPriority
        self.requestParams = nil
    }
    
    convenience init(requestURL:String?,
                     requestParams:Dictionary<String, AnyObject>?,
                     requestPriority:RequestPriority?) {
        self.init()
        
        self.requestURL = requestURL
        self.requestParams = requestParams
        self.priority = requestPriority
    }
}
