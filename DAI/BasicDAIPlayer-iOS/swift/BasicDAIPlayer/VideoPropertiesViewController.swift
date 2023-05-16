//
//  ViewController.swift
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK
import BrightcoveDAI

import GoogleInteractiveMediaAds


class VideoPropertiesViewController: BaseViewController {

    override func setupPlaybackController() {
        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerDelegate = self
        adsRenderingSettings.linkOpenerPresentingController = self

        let adsRequestPolicy = BCOVDAIAdsRequestPolicy.videoProperties();

        let daiSessionProvider = manager.createDAISessionProvider(with: imaSettings,
                                                                  adsRenderingSettings: adsRenderingSettings,
                                                                  adsRequestPolicy: adsRequestPolicy,
                                                                  adContainer: playerView!.contentOverlayView,
                                                                  viewController: self,
                                                                  companionSlots: nil,
                                                                  upstreamSessionProvider: nil)

        guard let playbackController = manager.createPlaybackController(with: daiSessionProvider,
                                                                        viewStrategy: nil) else {
            return
        }

        playbackController.delegate = self
        playbackController.isAutoPlay = true
        playbackController.isAutoAdvance = true

        playerView?.playbackController = playbackController

        self.playbackController = playbackController
    }

    override func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        let updatedVideo = video.update({ (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo = mutableVideo else {
                return
            }

            if var updatedProperties = mutableVideo.properties {
                updatedProperties[kBCOVDAIVideoPropertiesKeySourceId] = GoogleDAIConfig.SourceID
                updatedProperties[kBCOVDAIVideoPropertiesKeyVideoId] = GoogleDAIConfig.VideoID

                mutableVideo.properties = updatedProperties
            }
        })

        return updatedVideo
    }
}
