//
//  AppDelegate.swift
//  OfflinePlayer
//
//  Copyright © 2018 Brightcove, Inc. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    class func current() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    lazy var tabBarController: UITabBarController = {
        return window?.rootViewController as! UITabBarController
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // We need the below code in order to ensure that audio plays back when we
        // expect it to. For example, without setting this code, we won't hear the video
        // when the mute switch is on. For simplicity in the sample, we are going to
        // put this in the app delegate.  Check out https://developer.apple.com/Library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
        // for more information on how to use this in your own app.
        
        var categoryError :NSError?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            success = true
        } catch let error as NSError {
            categoryError = error
            success = false
        }
        
        if !success {
            print("AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. \(categoryError!)")
        }
        
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("performFetchWithCompletionHandler")
        
        completionHandler(UIBackgroundFetchResult.noData)
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession: \(identifier)")
        
        completionHandler()
    }

}

