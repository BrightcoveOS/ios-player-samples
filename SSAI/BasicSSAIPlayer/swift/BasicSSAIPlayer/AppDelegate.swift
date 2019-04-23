//
//  AppDelegate.swift
//  BasicSSAIPlayer
//
//  Created by Jeremy Blaker on 3/15/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Set the AVAudioSession category to allow audio playback in the background
        // or when the mute button is on. Refer to the AVAudioSession Class Reference:
        // https://developer.apple.com/documentation/avfoundation/avaudiosession
        
        var categoryError :NSError?
        var success: Bool
        do {
            // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
            // and https://developer.apple.com/documentation/avfoundation/avaudiosessionmodemovieplayback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .duckOthers)
            success = true
        } catch let error as NSError {
            categoryError = error
            success = false
        }
        
        if !success {
            print("AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. \(categoryError!)")
        }
        
        return true
    }
    
}


