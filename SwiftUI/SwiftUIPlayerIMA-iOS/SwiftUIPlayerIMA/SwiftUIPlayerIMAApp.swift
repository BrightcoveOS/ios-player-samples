//
//  SwiftUIPlayerIMAApp.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import SwiftUI

@main
struct SwiftUIPlayerIMAApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ConfigurationView()
            }
        }
    }
}
