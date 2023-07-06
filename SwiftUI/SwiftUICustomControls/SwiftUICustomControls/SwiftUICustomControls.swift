//
//  SwiftUICustomControls.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import AVFoundation

@main
struct SwiftUICustomControls: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setUpAudioSession()
                }
        }
    }
    
    private func setUpAudioSession() {
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
    }
}
