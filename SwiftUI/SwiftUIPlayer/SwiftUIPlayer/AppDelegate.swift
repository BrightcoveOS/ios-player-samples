//
//  AppDelegate.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import AVFoundation
import UIKit


final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
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
