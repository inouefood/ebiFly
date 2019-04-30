//
//  SauceModel.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/27.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation
import CoreMotion

protocol SauceModel {
    func shakeDevice(shaked:@escaping(Bool)->())
}

class SauceModelImpl: SauceModel {

    var motionManager:CMMotionManager
    private var x = 0
    private var y = 0
    private var z = 0
    
    init() {
        motionManager = CMMotionManager()
    }
    
    func shakeDevice(shaked: @escaping (Bool) ->()) {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue()) {
            (data, error) in
            DispatchQueue.main.async {
                let isShaken = self.x != Int(data!.acceleration.x) || self.y != Int(data!.acceleration.y) || self.z != Int(data!.acceleration.z)
                
                if isShaken {
                    shaked(true)
                } else {
                    shaked(false)
                }
                
                self.x = Int(data!.acceleration.x)
                self.y = Int(data!.acceleration.y)
                self.z = Int(data!.acceleration.z)
            }
        }
    }
}
