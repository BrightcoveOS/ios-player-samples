//
//  ViewController.swift
//  BasicDAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleInteractiveMediaAds
import BrightcoveDAI


final class VideoPropertiesViewController: BaseViewController {

    override func setupPlaybackController() {
        guard let sdkManager = BCOVPlayerSDKManager.shared(),
              let fps else { return }

        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerDelegate = self
        adsRenderingSettings.linkOpenerPresentingController = self

        let adsRequestPolicy = BCOVDAIAdsRequestPolicy.videoProperties();

        // BCOVDAIPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:
        // which allows us to modify the IMAStreamRequest object before it is used to load ads.
        let daiPlaybackSessionOptions = [ kBCOVDAIOptionDAIPlaybackSessionDelegateKey: self ]

        let daiSessionProvider = sdkManager.createDAISessionProvider(with: imaSettings,
                                                                     adsRenderingSettings: adsRenderingSettings,
                                                                     adsRequestPolicy: adsRequestPolicy,
                                                                     adContainer: playerView!.contentOverlayView,
                                                                     viewController: self,
                                                                     companionSlots: nil,
                                                                     upstreamSessionProvider: fps,
                                                                     options: daiPlaybackSessionOptions)

        guard let playerView,
              let playbackController = sdkManager.createPlaybackController(with: daiSessionProvider,
                                                                           viewStrategy: nil) else {
            return
        }

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

            if var updatedProperties = mutableVideo.properties {
                updatedProperties[kBCOVDAIVideoPropertiesKeySourceId] = kGoogleDAISourceId
                updatedProperties[kBCOVDAIVideoPropertiesKeyVideoId] = kGoogleDAIVideoId

                mutableVideo.properties = updatedProperties
            }
        }

        return updatedVideo
    }
}
