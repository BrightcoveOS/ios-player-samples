//
//  AppDelegate.swift
//  AppleTV
//
//  Created by Michael Moscardini on 3/10/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // We need the below code in order to ensure that audio plays back when we
        // expect it to. For example, without setting this code, we won't hear the video
        // when the mute switch is on. For simplicity in the sample, we are going to
        // put this in the app delegate.  Check out https://developer.apple.com/Library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
        // for more information on how to use this in your own app.
        
        var categoryError :NSError?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
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

