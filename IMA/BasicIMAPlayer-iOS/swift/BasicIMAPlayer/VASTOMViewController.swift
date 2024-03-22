//
//  VASTOMViewController.swift
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleInteractiveMediaAds
import BrightcoveIMA


final class VASTOMViewController: BaseViewController {

    override func setupPlaybackController() {
        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self
        renderSettings.linkOpenerDelegate = self

        let policy = BCOVCuePointProgressPolicy.init(processingCuePoints: .processFinalCuePoint,
                                                     resumingPlaybackFrom: .fromContentPlayhead,
                                                     ignoringPreviouslyProcessedCuePoints: false)

        // BCOVIMAAdsRequestPolicy provides two VAST configurations:
        // `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy` and
        // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
        //
        // Using `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy`
        // allows you to set a different VAST ad tag URL for each cue point, while using
        // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
        // will use the same VAST ad tag URL for each cue point.

        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vastAdTagsInCuePointsAndAdsCuePointProgressPolicy: policy)

        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
        // which allows us to modify the IMAAdsRequest object before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]

        guard let sdkManager = BCOVPlayerSDKManager.shared(),
              let playerView,
              let contentOverlayView = playerView.contentOverlayView,
              let fps,
              let imaSessionProvider = sdkManager.createIMASessionProvider(with: imaSettings,
                                                                           adsRenderingSettings: renderSettings,
                                                                           adsRequestPolicy: adsRequestPolicy,
                                                                           adContainer: contentOverlayView,
                                                                           viewController: self,
                                                                           companionSlots: companionAdSlots,
                                                                           upstreamSessionProvider: fps,
                                                                           options: imaPlaybackSessionOptions),
              let playbackController = sdkManager.createPlaybackController(with: imaSessionProvider,
                                                                           viewStrategy: nil) else {
            return
        }

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        self.playbackController = playbackController
    }

    override func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        return video.updateVideo(withVASTTag: kVASTOMAdTagURL)
    }


    // MARK: - BCOVPlaybackControllerAdsDelegate

    override func playbackController(_ controller: BCOVPlaybackController!,
                                     playbackSession session: BCOVPlaybackSession!,
                                     didEnter adSequence: BCOVAdSequence!) {

        super.playbackController(controller,
                                 playbackSession: session,
                                 didEnter: adSequence)

        guard let displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer] as? IMAAdDisplayContainer,
              let playerView,
              let transparentOverlay = playerView.overlayView else {
            return
        }

        let overlayObstruction = IMAFriendlyObstruction.init(view: transparentOverlay,
                                                             purpose: .notVisible,
                                                             detailedReason: "Transparent overlay does not impact viewability")

        displayContainer.register(overlayObstruction)
    }

    override func playbackController(_ controller: BCOVPlaybackController!,
                                     playbackSession session: BCOVPlaybackSession!,
                                     didExitAdSequence adSequence: BCOVAdSequence!) {

        super.playbackController(controller,
                                 playbackSession: session,
                                 didExitAdSequence: adSequence)

        guard let displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer] as? IMAAdDisplayContainer else { return }

        displayContainer.unregisterAllFriendlyObstructions()
    }

}
