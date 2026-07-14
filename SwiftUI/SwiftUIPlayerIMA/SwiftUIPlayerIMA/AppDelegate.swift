//
//  AppDelegate.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import AVFoundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAudioSession()
        return true
    }

    /// Configure the shared audio session for video playback.
    ///
    /// `.playback` keeps audio playing when the device is muted; `.duckOthers` lowers
    /// other apps' audio (e.g. background music) while we play. Combined with the
    /// `audio` background mode (Info.plist) and `allowsBackgroundAudioPlayback = true`
    /// on the playback controller, this enables PiP and AirPlay continuity.
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: .duckOthers
            )
        } catch {
            Log.session.error("Failed to set AVAudioSession category: \(error.localizedDescription, privacy: .public)")
        }
    }
}
