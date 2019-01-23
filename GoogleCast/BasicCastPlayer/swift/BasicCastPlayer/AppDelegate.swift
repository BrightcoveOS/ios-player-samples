//
//  AppDelegate.swift
//  BasicCastPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleCast

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
        
        // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#initialize_the_cast_context
        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: "4F8B3483")
        let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        GCKCastContext.setSharedInstanceWith(options)
        
        // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#add_expanded_controller
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
        
        // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#add_mini_controllers
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationController = storyboard.instantiateViewController(withIdentifier: "NavController")
        let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
        castContainerVC.miniMediaControlsItemEnabled = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = castContainerVC
        window?.makeKeyAndVisible()
        
        return true
    }


}

