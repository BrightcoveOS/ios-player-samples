//
//  ApplePlayerUIView.swift
//  SwiftUIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import AVKit
import SwiftUI

import BrightcovePlayerSDK


struct ApplePlayerUIView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AVPlayerViewController

    let playerModel: PlayerModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        if let playbackController = playerModel.playbackController {
            playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: true]
        }

        return playerModel.avPlayerViewController
    }

    func updateUIViewController(_ avPlayerViewController: AVPlayerViewController, context: Context) {}

}


// MARK: -

#if DEBUG
struct ApplePlayerUIView_Previews: PreviewProvider {
    static var previews: some View {
        let playerModel = PlayerModel()
        ApplePlayerUIView(playerModel: playerModel)
    }
}
#endif
