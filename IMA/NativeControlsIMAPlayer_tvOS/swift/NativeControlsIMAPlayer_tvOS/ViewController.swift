//
//  ViewController.swift
//  NativeControlsIMAPlayer_tvOS
//
//  Created by Jeremy Blaker on 6/1/20.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveIMA
import GoogleInteractiveMediaAds
import AVKit
import AppTrackingTransparency

fileprivate struct PlaybackConfig {
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let AccountID = "5434391461001"
    static let VideoID = "6140448705001"
}

struct IMAConfig {
    static let PublisherID = "insertyourpidhere"
    static let Language = "en"
    static let VMAPResponseAdTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1"
}

class ViewController: UIViewController {

    private lazy var playbackController: BCOVPlaybackController? = {
        
        let imaSettings = IMASettings()
        imaSettings.ppid = IMAConfig.PublisherID
        imaSettings.language = IMAConfig.Language
        
        let renderSettings = IMAAdsRenderingSettings()
        
        // Use the VMAP ads policy.
        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()
        
        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us
        // to modify the IMAAdsRequest object before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey : self]
        
        let imaSessionProvider = BCOVPlayerSDKManager.shared()?.createIMASessionProvider(with: imaSettings, adsRenderingSettings: renderSettings, adsRequestPolicy: adsRequestPolicy, adContainer: self.avpvc.contentOverlayView, viewController: self.avpvc, companionSlots: nil, upstreamSessionProvider: nil, options: imaPlaybackSessionOptions)
        
        guard let playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: imaSessionProvider, viewStrategy: nil) else {
            return nil
        }
    
        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        
        // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
        // since the AVPlayerViewController already makes one
        playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey : true]
        
        return playbackController
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        return BCOVPlaybackService(accountId: PlaybackConfig.AccountID, policyKey: PlaybackConfig.PolicyKey)
    }()

    private lazy var avpvc: AVPlayerViewController = {
        let avpvc = AVPlayerViewController()
        self.addChild(avpvc)
        self.view.addSubview(avpvc.view)
        avpvc.view.frame = self.view.frame
        avpvc.didMove(toParent: self)
        return avpvc
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(tvOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] (status: ATTrackingManager.AuthorizationStatus) in
                DispatchQueue.main.async {
                    self?.requestContentFromPlaybackService()
                }
            }
        } else {
            requestContentFromPlaybackService()
        }

    }
    
    // MARK: - Private
    
    private func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:PlaybackConfig.VideoID]
        playbackService.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            if let video = video {
                let updatedVideo = self?.updateVideoWithVMAPTag(video)
                self?.playbackController?.setVideos([updatedVideo] as NSFastEnumeration)
            }
            if let error = error {
                print("ViewController Debug - Error retrieving video: \(error)")
            }
        })
    }
    
    private func updateVideoWithVMAPTag(_ video: BCOVVideo) -> BCOVVideo {
        video.update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo = mutableVideo else {
                return
            }
            
            // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
            // the video's properties when using server side ad rules. This URL returns
            // a VMAP response that is handled by the Google IMA library.
            if var updatedProperties = mutableVideo.properties {
                updatedProperties[kBCOVIMAAdTag] = IMAConfig.VMAPResponseAdTag
                mutableVideo.properties = updatedProperties
            }
        }
    }
    
    private func buildMetadata(forVideo video: BCOVVideo) -> [AVMetadataItem] {
        // https://developer.apple.com/documentation/avkit/adding_information_to_the_info_panel_tvos/presenting_metadata_in_the_tvos_info_panel
        
        var metadataArray = [AVMetadataItem]()
        
        // Title
        if let title = video.properties[kBCOVVideoPropertyKeyName] as? String {
            metadataArray.append(makeMetadataItem(withIdentifier: AVMetadataIdentifier.commonIdentifierTitle, andValue: title))
        }
        
        // Desc
        if let desc = video.properties[kBCOVVideoPropertyKeyDescription] as? String {
            metadataArray.append(makeMetadataItem(withIdentifier: AVMetadataIdentifier.commonIdentifierDescription, andValue: desc))
        }
        
        // Poster
        if let posterURLString = video.properties[kBCOVVideoPropertyKeyPoster] as? String, let posterURL = URL(string: posterURLString) {
            do {
                let posterData = try Data(contentsOf: posterURL)
                metadataArray.append(makeMetadataItem(withIdentifier: AVMetadataIdentifier.commonIdentifierArtwork, andValue: posterData))
            } catch let error as NSError {
                print("Error fetching poster image data: \(error)")
            }

        }
        
        return metadataArray
    }
    
    private func makeMetadataItem(withIdentifier identifier: AVMetadataIdentifier, andValue value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        
        guard let video = session.video, let player = session.player, let playbackController = playbackController else {
            return
        }
        
        // Set the external metadata for the info view
        DispatchQueue.global(qos: .background).async {
            player.currentItem?.externalMetadata = self.buildMetadata(forVideo: video)
        }
        
        // Set the player on the AVPlayerViewController to begin playback
        avpvc.player = player
        
        if (playbackController.isAutoPlay) {
            avpvc.player?.play()
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
        // The events are defined BCOVIMAComponent.h.
        
        let type = lifecycleEvent.eventType
        
        if type == kBCOVIMALifecycleEventAdsLoaderLoaded {
            print("ViewController Debug - Ads loaded.")
            
            // When ads load successfully, the kBCOVIMALifecycleEventAdsLoaderLoaded lifecycle event
            // returns an NSDictionary containing a reference to the IMAAdsManager.
            guard let adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager] as? IMAAdsManager else {
                return
            }
            
            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0
            let volumeString = String(format: "%0.1", adsManager.volume)
            print("ViewController Debug - IMAAdsManager.volume set to \(volumeString)")
            
        } else if type == kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent {
            
            guard let adEvent = lifecycleEvent.properties["adEvent"] as? IMAAdEvent else {
                return
            }
            
            switch adEvent.type {
            case .STARTED:
                print("ViewController Debug - Ad Started.")
            case .COMPLETE:
                print("ViewController Debug - Ad Completed.")
            case .ALL_ADS_COMPLETED:
                print("ViewController Debug - All ads completed.")
            default:
                break
            }
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
        avpvc.showsPlaybackControls = false
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
        avpvc.showsPlaybackControls = true
    }
}

// MARK: - BCOVIMAPlaybackSessionDelegate

extension ViewController: BCOVIMAPlaybackSessionDelegate {
    
    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!, forPosition position: TimeInterval) {
        // for demo purposes, increase the VAST ad load timeout.
        adsRequest.vastLoadTimeout = 3000.0
        let timeoutStringFormat = String(format: "%.1", adsRequest.vastLoadTimeout)
        print("ViewController Debug - IMAAdsRequest.vastLoadTimeout set to \(timeoutStringFormat) milliseconds.")
    }
    
}

