//
//  ConfigurationView.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import SwiftUI

/// Root screen. Lets the user pick an ad delivery mode and start the player.
/// The mode is locked for the player session — to change it, the user
/// navigates back to this screen so SwiftUI tears the player view controller
/// down cleanly and a fresh IMA chain is built for the new mode.
struct ConfigurationView: View {

    @State private var adMode: AdMode = .vmap

    var body: some View {
        Form {
            Section {
                Picker("Mode", selection: $adMode) {
                    ForEach(AdMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(adMode.helpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Ad mode")
            } footer: {
                Text("Pick how the IMA plugin should fetch ads for this session.")
            }

            Section {
                NavigationLink {
                    PlayerView(adMode: adMode)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
            }
        }
        .navigationTitle("SwiftUI + IMA")
    }
}

extension AdMode {
    var helpText: String {
        switch self {
        case .vmap:
            "Single VMAP tag describes the full ad break schedule (server-side rules)."
        case .vast:
            "Per-cuepoint VAST: pre-roll, mid-roll, and post-roll triggered by client cuepoints."
        case .vastOM:
            "VAST + OMID: pre-roll with Open Measurement viewability tracking and friendly-obstruction registration over the player chrome."
        }
    }
}
