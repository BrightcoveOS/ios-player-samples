//
//  VASTOMViewController.swift
//  BasicIMAPlayer
//
//  Created by Carlos Ceja on 14/01/21.
//  Copyright © 2021 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveIMA
import GoogleInteractiveMediaAds

class VASTOMViewController: BaseViewController {

    private var useAdTagsInCuePoints = true

    override func setupPlaybackController() {
        let imaSettings = IMASettings()
        imaSettings.ppid = IMAConfig.PublisherID
        imaSettings.language = NSLocale.current.languageCode!

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self
        renderSettings.linkOpenerDelegate = self

        let policy = BCOVCuePointProgressPolicy.init(processingCuePoints: .processFinalCuePoint, resumingPlaybackFrom: .fromContentPlayhead, ignoringPreviouslyProcessedCuePoints: false)

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
        return video.updateVideo(withVASTTag: IMAConfig.VASTAdTagURL_openMeasurement) 
    }
    
    
// MARK: - BCOVPlaybackControllerDelegate

    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
        
        guard let displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer] as? IMAAdDisplayContainer,
              let transparentOverlay = self.playerView?.overlayView else { return }
        
        let overlayObstruction = IMAFriendlyObstruction.init(view: transparentOverlay, purpose: .notVisible, detailedReason: "Transparent overlay does not impact viewability")
        
        displayContainer.register(overlayObstruction)
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
        
        guard let displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer] as? IMAAdDisplayContainer else { return }

        displayContainer.unregisterAllFriendlyObstructions()
    }

}
