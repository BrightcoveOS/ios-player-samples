//
//  AssetKeyViewController.swift
//  BasicDAIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleInteractiveMediaAds
import BrightcoveDAI


final class AssetKeyViewController: BaseViewController {

    override func setupPlaybackController() {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        guard let fps, let playerView else { return }

        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode ?? "en"

        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerDelegate = self
        adsRenderingSettings.linkOpenerPresentingController = self

        let adsRequestPolicy = BCOVDAIAdsRequestPolicy.videoPropertiesAssetKey()

        // BCOVDAIPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:
        // which allows us to modify the IMAStreamRequest object before it is used to load ads.
        // kBCOVDAIOptionAutomaticRecoveryEnabledKey opts in to automatic DAI session
        // recovery (on by default; see BCOVDAIComponent.h). Particularly relevant for
        // Live DAI streams, where stitched ad URLs have a short TTL.
        let daiPlaybackSessionOptions: [String: Any] = [
            kBCOVDAIOptionDAIPlaybackSessionDelegateKey: self,
            kBCOVDAIOptionAutomaticRecoveryEnabledKey: true
        ]

        let daiSessionProvider = sdkManager.createDAISessionProvider(with: imaSettings,
                                                                     adsRenderingSettings: adsRenderingSettings,
                                                                     adsRequestPolicy: adsRequestPolicy,
                                                                     adContainer: playerView.contentOverlayView,
                                                                     viewController: self,
                                                                     companionSlots: nil,
                                                                     upstreamSessionProvider: fps,
                                                                     options: daiPlaybackSessionOptions)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: daiSessionProvider,
                                                                     viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoPlay = true
        playbackController.isAutoAdvance = true

        playerView.playbackController = playbackController

        self.playbackController = playbackController
    }

    override func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        let updatedVideo = video.update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo else {
                return
            }

            var updatedProperties = mutableVideo.properties
            updatedProperties[kBCOVDAIVideoPropertiesKeyAssetKey] = kGoogleDAIAssetKey

            mutableVideo.properties = updatedProperties
        }

        return updatedVideo
    }
}
