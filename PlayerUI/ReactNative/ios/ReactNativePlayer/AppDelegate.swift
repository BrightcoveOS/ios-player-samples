//
//  AppDelegate.swift
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AVFoundation
import UIKit
import React


@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        /*
         Set the AVAudioSession category to allow audio playback when:

         1: Silent Mode is enabled, or
         2: When the app is in the background, and
         2a:`allowsBackgroundAudioPlayback` is enabled on the playback controller, and/or
         2b:`allowsExternalPlayback` is enabled on the playback controller, and
         2c: "Audio, AirPlay, and Picture in Picture" is enabled as a Background Mode capability.

         Refer to the AVAudioSession Class Reference:
         https://developer.apple.com/documentation/avfoundation/avaudiosession
         */

        do {
            // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
            // and https://developer.apple.com/documentation/avfoundation/avaudiosessionmodemovieplayback
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            mode: .moviePlayback,
                                                            options: .duckOthers)
        } catch {
            print("AppDelegate - Error setting AVAudioSession category. Because of this, there may be no sound. \(error)")
        }

        guard let bridge = RCTBridge(delegate: self,
                                     launchOptions: launchOptions) else {
            return true
        }

        let rootView = RCTRootView(bridge: bridge,
                                   moduleName: "ReactNativePlayer",
                                   initialProperties: nil)

        window = UIWindow(frame: UIScreen.main.bounds)

        guard let window else { return true }
        let rootViewController = UIViewController()
        rootViewController.view = rootView
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        return true
    }

}


// MARK: - RCTBridgeDelegate

extension AppDelegate: RCTBridgeDelegate {

    func sourceURL(for bridge: RCTBridge!) -> URL! {
#if DEBUG
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
        return Bundle.main.url(forResource: "main",
                               withExtension: "jsbundle")
#endif
    }
}
