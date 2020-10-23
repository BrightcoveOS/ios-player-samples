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
    
    override func setupPlaybackController() {
        let imaSettings = IMASettings()
        imaSettings.ppid = IMAConfig.PublisherID
        imaSettings.language = IMAConfig.Language
        
        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.webOpenerPresentingController = self
        renderSettings.webOpenerDelegate = self
        
        // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()
        
        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us to modify the IMAAdsRequest object
        // before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]
        
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createIMAPlaybackController(with: imaSettings, adsRenderingSettings: renderSettings, adsRequestPolicy: adsRequestPolicy, adContainer: playerView?.contentOverlayView, viewController: self, companionSlots: nil, viewStrategy: nil, options: imaPlaybackSessionOptions) else {
            return
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        // Creating a playback controller based on the above code will create
        // VMAP / Server Side Ad Rules. These settings are explained in BCOVIMAAdsRequestPolicy.h.
        // If you want to change these settings, you can initialize the plugin like so:
        //
        // let adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vmapAdTagUrl: IMAConfig.VMAPResponseAdTag)
        
        self.playbackController = _playbackController
    }

    override func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        return video.updateVideo(withVMAPTag: IMAConfig.VMAPAdTagURL)
    }

}
