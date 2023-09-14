//
//  PlayerModel.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import AVKit
import SwiftUI

import BrightcovePlayerSDK


final class PlayerModel: NSObject, ObservableObject, AVPlayerViewControllerDelegate, BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate {

    @Published var fullscreenEnabled = false
    @Published var pictureInPictureEnabled = false

    private(set) lazy var avpvc: AVPlayerViewController = {
        let _avpvc = AVPlayerViewController()
        _avpvc.delegate = self
        return _avpvc
    }()

    private(set) lazy var controller: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.shared()

        let fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)!
        let basicSessionProvider = sdkManager?.createBasicSessionProvider(with:nil)
        let fairplaySessionProvider = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate:nil, authorizationProxy:fairPlayAuthProxy, upstreamSessionProvider:basicSessionProvider)

        guard let _playbackController = sdkManager?.createPlaybackController(with: fairplaySessionProvider, viewStrategy: nil) else {
            return nil
        }

        _playbackController.delegate = self
        _playbackController.isAutoPlay = true
        _playbackController.isAutoAdvance = false

        return _playbackController
    }()


    // MARK: BCOVPlaybackControllerDelegate

    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        if let options = controller.options, let useNative = options[kBCOVAVPlayerViewControllerCompatibilityKey] as? Bool, useNative {
            if let player = session?.player {
                avpvc.player = player
            }
        }

        print("BCOVPlaybackControllerDelegate Debug - Advanced to new session.")
    }


    // MARK: BCOVPUIPlayerViewDelegate

    func playerView(_ playerView: BCOVPUIPlayerView!, willTransitionTo screenMode: BCOVPUIScreenMode) {
        fullscreenEnabled = screenMode == .full
    }

    func pictureInPictureControllerDidStartPicture(inPicture pictureInPictureController: AVPictureInPictureController!) {
        pictureInPictureEnabled = true
    }

    func pictureInPictureControllerDidStopPicture(inPicture pictureInPictureController: AVPictureInPictureController!) {
        pictureInPictureEnabled = false
    }


    // MARK: AVPlayerViewControllerDelegate

    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { [weak self] context in
            self?.fullscreenEnabled = true
        }
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { [weak self] context in
            self?.fullscreenEnabled = false
        }
    }

    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        pictureInPictureEnabled = true
    }

    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        pictureInPictureEnabled = false
    }

}
