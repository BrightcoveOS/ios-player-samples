//
//  PlayerModel.swift
//  SwiftUICustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AVKit
import SwiftUI
import BrightcovePlayerSDK
import BrightcoveIMA
import GoogleInteractiveMediaAds


final class PlayerModel: NSObject, ObservableObject {

    @Published
    var fullscreenEnabled = false

    @Published
    var pictureInPictureEnabled = false

    fileprivate(set) lazy var avpvc: AVPlayerViewController = {
        let avpvc = AVPlayerViewController()
        avpvc.delegate = self
        return avpvc
    }()

    // This will be set by the view controller that has access to the playerView's contentOverlayView
    var playbackController: BCOVPlaybackController?

}


// MARK: - AVPlayerViewControllerDelegate

extension PlayerModel: AVPlayerViewControllerDelegate {

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { [weak self] _ in
            self?.fullscreenEnabled = true
        }
    }

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { [weak self] _ in
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


// MARK: - BCOVPlaybackControllerDelegate

extension PlayerModel: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        if let player = session?.player,
           let options = controller.options,
           let useNative = options[kBCOVAVPlayerViewControllerCompatibilityKey] as? Bool,
           useNative {
            avpvc.player = player
        }

        print("PlayerModel - Advanced to new session.")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("PlayerModel - Playback error: \(error.localizedDescription)")
        }

        // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
        // The events are defined BCOVIMAComponent.h.
        if kBCOVIMALifecycleEventAdsLoaderLoaded == lifecycleEvent.eventType,
           let adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager] as? IMAAdsManager {
            print("PlayerModel - Ads loaded.")

            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0
            print("PlayerModel - IMAAdsManager.volume set to \(String(format: "%0.1f", adsManager.volume))")

        } else if kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent == lifecycleEvent.eventType,
                  let adEvent = lifecycleEvent.properties["adEvent"] as? IMAAdEvent {
            switch adEvent.type {
                case .STARTED:
                    print("PlayerModel - Ad Started.")
                case .COMPLETE:
                    print("PlayerModel - Ad Completed.")
                case .ALL_ADS_COMPLETED:
                    print("PlayerModel - All ads completed.")
                default:
                    break
            }
        }
    }

}


// MARK: - BCOVPUIPlayerViewDelegate

extension PlayerModel: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!, willTransitionTo screenMode: BCOVPUIScreenMode) {
        fullscreenEnabled = screenMode == .full
    }

    func pictureInPictureControllerDidStartPicture(inPicture pictureInPictureController: AVPictureInPictureController!) {
        pictureInPictureEnabled = true
    }

    func pictureInPictureControllerDidStopPicture(inPicture pictureInPictureController: AVPictureInPictureController!) {
        pictureInPictureEnabled = false
    }
}

// MARK: - BCOVPlaybackControllerAdsDelegate

extension PlayerModel: BCOVPlaybackControllerAdsDelegate {

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAdSequence adSequence: BCOVAdSequence) {
        print("PlayerModel - Entering ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAdSequence adSequence: BCOVAdSequence) {
        print("PlayerModel - Exiting ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAd ad: BCOVAd) {
        print("PlayerModel - Entering ad")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAd ad: BCOVAd) {
        print("PlayerModel - Exiting ad")
    }

}

// MARK: - IMALinkOpenerDelegate

extension PlayerModel: IMALinkOpenerDelegate {

    func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
        print("PlayerModel - linkOpenerDidOpen")
    }

    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        print("PlayerModel - linkOpenerDidClose")

        // Called when the in-app browser has closed.
        guard let playbackController = playbackController else { return }
        playbackController.resumeAd()
    }
}

// MARK: - BCOVIMAPlaybackSessionDelegate

extension PlayerModel: BCOVIMAPlaybackSessionDelegate {

    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!,
                                        forPosition position: TimeInterval) {
        // for demo purposes, increase the VAST ad load timeout.
        adsRequest.vastLoadTimeout = 3000.0
        print("PlayerModel - IMAAdsRequest.vastLoadTimeout set to \(String(format: "%.1f", adsRequest.vastLoadTimeout)) milliseconds.")
    }
}
