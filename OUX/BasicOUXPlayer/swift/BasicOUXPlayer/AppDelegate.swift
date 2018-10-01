//
//  AppDelegate.swift
//  BasicOUXPlayer
//
//  Copyright © 2018 Brightcove, Inc. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // We need the below code in order to ensure that audio plays back when we
        // expect it to. For example, without setting this code, we won't hear the video
        // when the mute switch is on. For simplicity in the sample, we are going to
        // put this in the app delegate.  Check out https://developer.apple.com/Library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
        // for more information on how to use this in your own app.
        
        if #available(iOS 10.0, *) {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            } catch {
                print("AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound.")
            }
        }
        else {
            // Workaround until https://forums.swift.org/t/using-methods-marked-unavailable-in-swift-4-2/14949 is fixed
            AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
        }
        
        return true
    }

}

