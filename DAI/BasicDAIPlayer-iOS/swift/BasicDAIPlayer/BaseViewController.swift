//
//  BaseViewController.swift
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
    static let AssetKey = "sN_IYUG8STe1ZzhIIE_ksA"
}


class BaseViewController: UIViewController {
    
    @IBOutlet weak var videoContainerView: UIView!
    
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

    private(set) lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true

        guard let playerView = BCOVPUIPlayerView.init(playbackController: nil,
                                                      options: options,
                                                      controlsView: nil) else {
            return nil
        }

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)

        return playerView
    }()
    
    var playbackController: BCOVPlaybackController?
    
    fileprivate(set) lazy var adIsPlaying: Bool = false

    private(set) var notificationReceipt: Any?

    deinit {
        NotificationCenter.default.removeObserver(notificationReceipt!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in
                DispatchQueue.main.async(execute: {
                    self.setup()
                })
            })
        }
        else {
            setup()
        }
    }

    private func setup() {
        setupPlaybackController()
        resumeAdAfterForeground()
        requestContentFromPlaybackService()
    }

    func setupPlaybackController() {
        // NO-OP
    }

    func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        return video
    }

    private func resumeAdAfterForeground() {
        // When the app goes to the background, the Google IMA library will pause
        // the ad. This code demonstrates how you would resume the ad when entering
        // the foreground.

        notificationReceipt = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            if strongSelf.adIsPlaying {
                strongSelf.playbackController?.resumeAd()
            }
        })
    }

    private func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: PlaybackConfig.VideoID]

        playbackService?.findVideo(withConfiguration: configuration,
                                   queryParameters: nil,
                                   completion: { [weak self] (video: BCOVVideo?,
                                                              jsonResponse: [AnyHashable: Any]?,
                                                              error: Error?) in

            guard let strongSelf = self else {
                return
            }

            if let video = video {
                let updatedVideo = strongSelf.updateVideo(video)
                strongSelf.playbackController?.setVideos([updatedVideo] as NSFastEnumeration)
            }
            else {
                print("ViewController Debug - Error retrieving video")
            }
        })
    }
}


// MARK: BCOVPlaybackControllerDelegate

extension BaseViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")

        // Enable route detection for AirPlay
        // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
        playerView?.controlsView?.routeDetector.isRouteDetectionEnabled = true
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
                adIsPlaying = true
                break
            case .COMPLETE:
                print("ViewController Debug - Ad Completed.");
                adIsPlaying = false
                break
            case .ALL_ADS_COMPLETED:
                print("ViewController - All ads completed.")
                break
            default:
                break
            }
        }
        else if type == kBCOVPlaybackSessionLifecycleEventEnd {
            // Disable route detection for AirPlay
            // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
            playerView?.controlsView?.routeDetector.isRouteDetectionEnabled = false
        }
    }
}


// MARK: IMALinkOpenerDelegate

extension BaseViewController: IMALinkOpenerDelegate {

    func linkOpenerWillOpen(inAppLink linkOpener: NSObject) {
        print("IMALinkOpenerDelegate: In-app browser will open")
    }

    func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
        print("IMALinkOpenerDelegate: In-app browser did open")
    }

    func linkOpenerWillClose(inAppLink linkOpener: NSObject) {
        print("IMALinkOpenerDelegate: In-app browser will close")
    }

    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        print("IMALinkOpenerDelegate: In-app browser did close")

        if adIsPlaying {
            playbackController?.resumeAd()
        }
    }
}
