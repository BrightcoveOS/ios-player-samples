//
//  BCOVPlayerViewControllerRepresentable.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

/// A SwiftUI view that wraps BCOVPUIPlayerViewController using UIViewControllerRepresentable.
///
/// This is the recommended approach for SwiftUI apps that need:
/// - IMA ads or other ad integrations
/// - Proper view controller hierarchy for presenting modals
/// - Full compatibility with UIKit-based features
///
/// **Why use UIViewControllerRepresentable instead of UIViewRepresentable?**
///
/// When you wrap BCOVPUIPlayerView (a UIView) directly in UIViewRepresentable,
/// there's no proper UIViewController in the hierarchy. This causes issues with:
/// - IMA ads: Google's IMAAdViewController needs a parent view controller
/// - Error: "child view controller should have parent view controller but actual parent is..."
///
/// BCOVPUIPlayerViewController solves this by providing a proper UIViewController
/// that sets itself as the presenting view controller, ensuring correct hierarchy.
///
/// **Comparison with BCOVPlayerUIView:**
/// - BCOVPlayerUIView: UIViewRepresentable → BCOVPUIPlayerView (UIView)
/// - BCOVPlayerViewControllerRepresentable: UIViewControllerRepresentable → BCOVPUIPlayerViewController (UIViewController)
///
/// For apps without ads, either approach works. For apps with IMA ads, use this approach.
struct BCOVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = BCOVPUIPlayerViewController

    let playerModel: PlayerModel

    func makeUIViewController(context: Context) -> BCOVPUIPlayerViewController {
        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true

        guard let playbackController = playerModel.playbackController else {
            return BCOVPUIPlayerViewController(playbackController: nil,
                                               options: options,
                                               controlsView: nil)
        }

        let playerViewController = BCOVPUIPlayerViewController(playbackController: playbackController,
                                                               options: options,
                                                               controlsView: nil)
        
        playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: false]
        playerViewController.delegate = playerModel
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: BCOVPUIPlayerViewController, context: Context) {
        // No updates needed
    }
}

#if DEBUG
struct BCOVPlayerViewControllerRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        let playerModel = PlayerModel()
        BCOVPlayerViewControllerRepresentable(playerModel: playerModel)
    }
}
#endif
