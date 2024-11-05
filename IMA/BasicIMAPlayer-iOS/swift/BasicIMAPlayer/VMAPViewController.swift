//
//  VMAPViewController.swift
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleInteractiveMediaAds
import BrightcoveIMA


final class VMAPViewController: BaseViewController {

    override func setupPlaybackController() {
        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self
        renderSettings.linkOpenerDelegate = self

        // BCOVIMAAdsRequestPolicy provides two VMAP configurations:
        // `videoPropertiesVMAPAdTagUrlAdsRequestPolicy` and
        // `adsRequestPolicyWithVMAPAdTagUrl:`
        //
        // Using `videoPropertiesVMAPAdTagUrlAdsRequestPolicy` allows you to
        // set a different VMAP ad tag URL for each video, while using
        // `adsRequestPolicyWithVMAPAdTagUrl:` will use the same VMAP ad tag URL
        // for each video.

        var adsRequestPolicy: BCOVIMAAdsRequestPolicy?

        if (useVideoProperties) {
            adsRequestPolicy = .videoPropertiesVMAPAdTagUrl()
        } else {
            adsRequestPolicy = .init(vmapAdTagUrl: kVMAPAdTagURL)
        }

        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
        // which allows us to modify the IMAAdsRequest object before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]

        let sdkManager = BCOVPlayerSDKManager.sharedManager()

        guard let playerView,
              let contentOverlayView = playerView.contentOverlayView,
              let fps,
              let imaSessionProvider = sdkManager.createIMASessionProvider(with: imaSettings,
                                                                           adsRenderingSettings: renderSettings,
                                                                           adsRequestPolicy: adsRequestPolicy,
                                                                           adContainer: contentOverlayView,
                                                                           viewController: self,
                                                                           companionSlots: companionAdSlots,
                                                                           upstreamSessionProvider: fps,
                                                                           options: imaPlaybackSessionOptions) else {
            return
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: imaSessionProvider,
                                                                     viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        self.playbackController = playbackController
    }

    fileprivate var useVideoProperties = true

    override func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        if useVideoProperties {
            return video.updateVideo(withVMAPTag: kVMAPAdTagURL)
        }

        return video
    }

}
