//
//  BCOVVideoPlayerManager.swift
//  PlayerReactNative
//
//  Created by Carlos Ceja.
//

import Foundation
import UIKit

import React

@objc(BCOVVideoPlayerManager)
class BCOVVideoPlayerManager: RCTViewManager {

    @objc 
    override func view() -> UIView! {
        return BCOVVideoPlayer(eventDispatcher: self.bridge.eventDispatcher())
    }
    
    func methodQueue() -> DispatchQueue {
        return self.bridge.uiManager.methodQueue
    }
    
    override static func requiresMainQueueSetup() -> Bool {
      return true
    }
    
    @objc func updateFromManager(_ node: NSNumber, count: NSNumber) {
      DispatchQueue.main.async {
//        let component = self.bridge.uiManager.view(
//          forReactTag: node
//        ) as! CounterView
//        component.update(value: count)
      }
    }

}
