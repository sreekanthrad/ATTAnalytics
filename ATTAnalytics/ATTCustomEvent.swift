//
//  ATTCustomEvent.swift
//  TrackingHelper
//
//  Created by Sreekanth R on 27/01/17.
//  Copyright © 2017 Sreekanth R. All rights reserved.
//

import UIKit

public class ATTCustomEvent: NSObject {
    
    var duration:Double?
    
    private var startTime:Date?
    private var endTime:Date?
    
    public func eventStarted() -> Void {
        self.startTime = Date()
    }
    
    public func eventFinished() -> Void {
        self.endTime = Date()
        self.duration = self.endTime?.timeIntervalSince(self.startTime!)
    }
}
