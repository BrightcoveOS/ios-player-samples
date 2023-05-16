//
//  ViewController.swift
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import AppTrackingTransparency
import UIKit

import BrightcovePlayerSDK
import BrightcoveDAI

import GoogleInteractiveMediaAds


// ** Customize these values with your own account information **
struct PlaybackConfig {
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let AccountID = "5434391461001"
    static let VideoID = "1753980443013591663"
}

struct GoogleDAIConfig {
    static let SourceID = "2528370"
    static let VideoID = "tears-of-steel"
}

class ViewController: UIViewController {
    
    @IBOutlet var videoContainerView: UIView!

    private(set) lazy var manager: BCOVPlayerSDKManager = {
        return BCOVPlayerSDKManager.shared()
    }()

    private(set) lazy var playbackService: BCOVPlaybackService? = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: PlaybackConfig.AccountID,
                                                        policyKey: PlaybackConfig.PolicyKey)
        guard let service = BCOVPlaybackService.init(requestFactory: factory) else {
            return nil
        }
        
        return service
    }()
    
    private(set) lazy var playerView: BCOVTVPlayerView? = {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true
        
        guard let playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)

        return playerView
    }()

    private(set) lazy var playbackController: BCOVPlaybackController? = {
        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let adsRenderingSettings = IMAAdsRenderingSettings()

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
            return nil
        }

        playbackController.delegate = self
        playbackController.isAutoPlay = true
        playbackController.isAutoAdvance = true

        playerView?.playbackController = playbackController
        
        return playbackController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(tvOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in
                DispatchQueue.main.async(execute: {
                    self.requestContentFromPlaybackService()
                })
            })
        }
        else {
            requestContentFromPlaybackService()
        }
    }

    private func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: PlaybackConfig.VideoID]

        playbackService?.findVideo(withConfiguration: configuration,
                                   queryParameters: nil,
                                   completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in

            guard let strongSelf = self else {
                return
            }

            if let video = video {
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

                strongSelf.playbackController?.setVideos([updatedVideo] as NSFastEnumeration)
            }
            else {
                print("ViewController Debug - Error retrieving video")
            }
        })
    }

    // MARK: UI
    // Preferred focus for tvOS 10+
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [playerView?.controlsView ?? self]
    }

}


// MARK: BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }

    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        // Ad events are emitted by the BCOVDAI plugin through lifecycle events.
        // The events are defined BCOVDAIComponent.h
        let type = lifecycleEvent.eventType
        if type == kBCOVDAILifecycleEventAdsLoaderLoaded {
            print("ViewController Debug - Ads loaded.")
        }
        else if type == kBCOVDAILifecycleEventAdsManagerDidReceiveAdEvent {
            guard let adEvent = lifecycleEvent.properties["adEvent"] as? IMAAdEvent else {
                return
            }

            switch adEvent.type {
            case .STARTED:
                print("ViewController Debug - Ad Started.")
                break
            case .COMPLETE:
                print("ViewController Debug - Ad Completed.");
                break
            case .ALL_ADS_COMPLETED:
                print("ViewController - All ads completed.")
                break
            default:
                break
            }
        }
    }
}

