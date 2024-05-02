//
//  BCOVPlayerUIView.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI

import BrightcovePlayerSDK


struct BCOVPlayerUIView: UIViewRepresentable {
    typealias UIViewType = BCOVPUIPlayerView

    let playerModel: PlayerModel

    func makeUIView(context: Context) -> BCOVPUIPlayerView {
        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true

        guard let playbackController = playerModel.playbackController,
              let playerView = BCOVPUIPlayerView(playbackController: playbackController,
                                                 options: options,
                                                 controlsView: nil) else {
            return BCOVPUIPlayerView()
        }

        playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: false]

        playerView.delegate = playerModel

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
