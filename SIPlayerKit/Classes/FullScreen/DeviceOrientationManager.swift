//
//  DeviceOrientationManager.swift
//  CustomPlayer
//
//  Created by Paco on 31/1/2023.
//

import Foundation
import CoreMotion
import UIKit
import Combine

final class DeviceOrientationManager {
    
    private lazy var motionManager: CMMotionManager = {
        let m = CMMotionManager()
        m.accelerometerUpdateInterval = 1.5
        return m
    }()
    
    private let queue = OperationQueue()
    
    private let motionLimit = 0.6
    
    /// read only current device orientation
    let deviceOrientation: CurrentValueSubject<UIDeviceOrientation, Never> = {
        return CurrentValueSubject(.portrait)
    }()
    
    /// Listen to device orientation changes
    public func startObserveDeviceMotion() {
        queue.cancelAllOperations()
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            guard let accelerometerData = data else {
                return
            }
            
            var newDeviceOrientation: UIDeviceOrientation?
            
            if accelerometerData.acceleration.x >= self.motionLimit {
                newDeviceOrientation = .landscapeRight
            } else if accelerometerData.acceleration.x <= -self.motionLimit {
                newDeviceOrientation = .landscapeLeft
            } else if accelerometerData.acceleration.y >= self.motionLimit {
                newDeviceOrientation = .portraitUpsideDown
            } else if accelerometerData.acceleration.y <= -self.motionLimit {
                newDeviceOrientation = .portrait
            } else {
                return
            }
            
            guard let newDeviceOrientation = newDeviceOrientation else { return }
            
            /// Only if a different orientation is detect
            if newDeviceOrientation != self.deviceOrientation.value {
                /// Update the class state
                self.deviceOrientation.send(newDeviceOrientation)
            }
        }
    }
    
    /// Stop the notifier
    public func stopObserveDeviceMotion() {
        motionManager.stopAccelerometerUpdates()
        queue.cancelAllOperations()
    }
}
