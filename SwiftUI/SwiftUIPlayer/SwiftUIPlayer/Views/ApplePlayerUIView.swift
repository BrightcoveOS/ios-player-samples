//
//  ApplePlayerUIView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import AVKit
import SwiftUI

import BrightcovePlayerSDK


struct ApplePlayerUIView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AVPlayerViewController

    let playerModel: PlayerModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        playerModel.controller?.options = [kBCOVAVPlayerViewControllerCompatibilityKey: true]

        return playerModel.avpvc
    }

    func updateUIViewController(_ avpvc: AVPlayerViewController, context: Context) {}

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
