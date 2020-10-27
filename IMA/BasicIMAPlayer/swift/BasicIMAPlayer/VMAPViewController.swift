//
//  VMAPViewController.swift
//  BasicIMAPlayer
//
//  Created by Jeremy Blaker on 10/26/20.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveIMA
import GoogleInteractiveMediaAds

class VMAPViewController: BaseViewController {
    
    private var useVideoProperties = true
    
    override func setupPlaybackController() {
        let imaSettings = IMASettings()
        imaSettings.ppid = IMAConfig.PublisherID
        imaSettings.language = IMAConfig.Language
        
        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.webOpenerPresentingController = self
        renderSettings.webOpenerDelegate = self
        
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
            adsRequestPolicy = BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()
        } else {
            adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vmapAdTagUrl: IMAConfig.VMAPAdTagURL)
        }
                
        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
        // which allows us to modify the IMAAdsRequest object before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]
        
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createIMAPlaybackController(with: imaSettings, adsRenderingSettings: renderSettings, adsRequestPolicy: adsRequestPolicy, adContainer: playerView?.contentOverlayView, viewController: self, companionSlots: nil, viewStrategy: nil, options: imaPlaybackSessionOptions) else {
            return
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController

        self.playbackController = _playbackController
    }

    override func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        if (useVideoProperties) {
            return video.updateVideo(withVMAPTag: IMAConfig.VMAPAdTagURL)
        }
        return video
    }

}
