//
//  BCOVPlayerUIView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI

import BrightcovePlayerSDK


struct BCOVPlayerUIView: UIViewRepresentable {
    typealias UIViewType = BCOVPUIPlayerView

    let playerModel: PlayerModel

    func makeUIView(context: Context) -> BCOVPUIPlayerView {
        playerModel.controller?.options = [kBCOVAVPlayerViewControllerCompatibilityKey: false]

        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true

        let playerView = BCOVPUIPlayerView(playbackController: playerModel.controller, options: options, controlsView: nil)!
        playerView.delegate = playerModel

        return playerView
    }

    func updateUIView(_ uiView: BCOVPUIPlayerView, context: Context) {}

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
