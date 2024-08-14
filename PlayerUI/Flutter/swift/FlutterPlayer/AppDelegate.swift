//
//  AppDelegate.swift
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AVFoundation
import UIKit
import Flutter


@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var flutterViewController: FlutterViewController?

    fileprivate(set) lazy var flutterEngine: FlutterEngine = .init(name: "io.flutter")

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

        // Runs the default Dart entrypoint with a default Flutter route.
        flutterEngine.run()

        if let registrar = flutterEngine.registrar(forPlugin: "BCOVFlutterPlugin") {
            BCOVFlutterPlugin.register(with: registrar)
        }

        let flutterViewController: FlutterViewController = .init(engine: flutterEngine,
                                                                              nibName: nil,
                                                                              bundle: nil)

        self.flutterViewController = flutterViewController

        window = .init(frame: UIScreen.main.bounds)
        window?.rootViewController = self.flutterViewController
        window?.makeKeyAndVisible()

        return true
    }
}
