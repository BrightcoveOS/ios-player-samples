//
//  BCOVPlayerRepresentable.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import SwiftUI

/// SwiftUI bridge for `IMAPlayerViewController`.
///
/// One VC instance per `PlayerView` mount — the ad mode is locked at
/// `PlayerViewModel` construction. Switching ad modes requires navigating
/// back to the configuration screen so SwiftUI tears the VC down cleanly.
struct BCOVPlayerRepresentable: UIViewControllerRepresentable {

    let viewModel: PlayerViewModel

    func makeUIViewController(context: Context) -> IMAPlayerViewController {
        IMAPlayerViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: IMAPlayerViewController, context: Context) {
        // Nothing to update — the VC owns its IMA chain for its lifetime.
    }

    /// SwiftUI calls this when the representable is permanently removed
    /// (e.g. the user navigates back from `PlayerView`). The IMA chain
    /// otherwise keeps a strong reference to the view model, so we have
    /// to tell the VC to release it explicitly.
    static func dismantleUIViewController(_ uiViewController: IMAPlayerViewController, coordinator: ()) {
        uiViewController.shutdown()
    }
}
