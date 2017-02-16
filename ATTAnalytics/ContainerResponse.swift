//
//  ContainerResponse.swift
//  Sample
//
//  Created by Sreekanth R on 27/10/16.
//  Copyright © 2016 Sreekanth R. All rights reserved.
//

import Foundation

class ContainerResponse: NSObject {
    // MARK: Properties
    var responseDictionary:Dictionary<String, AnyObject>?
    var responseError:Error?
    var response:URLResponse?
    
    // MARK: Constructor
    override init() {
        super.init()
    }
    
    convenience init(parsedResponse:Dictionary<String, AnyObject>?,
                     error:Error?,
                     response:URLResponse?) {
        self.init()
        
        self.responseDictionary = parsedResponse
        self.responseError = error
        self.response = response
    }
}
