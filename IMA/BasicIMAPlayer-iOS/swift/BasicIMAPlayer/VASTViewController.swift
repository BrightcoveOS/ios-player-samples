//
//  VASTViewController.swift
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleInteractiveMediaAds
import BrightcoveIMA


final class VASTViewController: BaseViewController {

    fileprivate var useAdTagsInCuePoints = true

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

        var adsRequestPolicy: BCOVIMAAdsRequestPolicy?

        if useAdTagsInCuePoints {
            adsRequestPolicy = .init(vastAdTagsInCuePointsAndAdsCuePointProgressPolicy: policy)
        } else {
            adsRequestPolicy = .init(fromCuePointPropertiesWithAdTag: kVASTAdTagURL,
                                     adsCuePointProgressPolicy: policy)
        }

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
        return video.updateVideo(useAdTagsInCuePoints: useAdTagsInCuePoints)
    }
}
