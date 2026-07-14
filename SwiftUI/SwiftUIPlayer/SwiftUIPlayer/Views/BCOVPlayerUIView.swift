//
//  BCOVPlayerUIView.swift
//  SwiftUIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import SwiftUI

import BrightcovePlayerSDK

/// A SwiftUI view that wraps BCOVPUIPlayerView using UIViewRepresentable.
///
/// This is a simple approach for integrating Brightcove's player UI in SwiftUI.
///
/// **Best for:**
/// - SwiftUI apps that don't use IMA ads
/// - Simple video playback with Brightcove's built-in controls
/// - When you don't need complex view controller hierarchy
///
/// **Limitations:**
/// - May cause view controller hierarchy issues with IMA ads
/// - The player view doesn't have a dedicated UIViewController parent
/// - For IMA ads, use BCOVPlayerViewControllerRepresentable instead
///
/// **Pattern:**
/// UIViewRepresentable → BCOVPUIPlayerView (UIView) → Playback Controller
///
/// **See also:** BCOVPlayerViewControllerRepresentable for the view controller-based approach.
struct BCOVPlayerUIView: UIViewRepresentable {
    typealias UIViewType = BCOVPUIPlayerView

    let playerModel: PlayerModel

    func makeUIView(context: Context) -> BCOVPUIPlayerView {
        guard let playerView = playerModel.bcovPlayerView else {
            return BCOVPUIPlayerView()
        }

        playerModel.playbackController?.options = [kBCOVAVPlayerViewControllerCompatibilityKey: false]

        return playerView
    }

    func updateUIView(_ playerView: BCOVPUIPlayerView, context: Context) {}

}


// MARK: -

#if DEBUG
struct BCOVPlayerUIView_Previews: PreviewProvider {
    static var previews: some View {
        let playerModel = PlayerModel()
        BCOVPlayerUIView(playerModel: playerModel)
    }
}
#endif
