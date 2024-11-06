//
//  BaseViewController.swift
//  BasicDAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import GoogleInteractiveMediaAds
import BrightcoveDAI


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "1753980443013591663"


let kGoogleDAISourceId = "2528370"
let kGoogleDAIVideoId = "tears-of-steel"
let kGoogleDAIAssetKey = "sN_IYUG8STe1ZzhIIE_ksA"



class BaseViewController: UIViewController {
    
    @IBOutlet fileprivate weak var videoContainerView: UIView!

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate(set) lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true

        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: nil) else {
            return nil
        }

        playerView.delegate = self

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)

        return playerView
    }()

    fileprivate(set) lazy var fps: BCOVPlaybackSessionProvider? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        return sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                        upstreamSessionProvider: nil)
    }()

    var playbackController: BCOVPlaybackController?

    fileprivate var notificationReceipt: AnyObject?
    fileprivate lazy var adIsPlaying = false
    fileprivate lazy var isBrowserOpen = false

    fileprivate lazy var statusBarHidden = false {
        didSet {
            if let navigationController {
                navigationController.isNavigationBarHidden = statusBarHidden
            }

            navigationItem.hidesBackButton = statusBarHidden

            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlaybackController()

        resumeAdAfterForeground()

        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch (status) {
                    case .authorized:
                        print("Authorized Tracking Permission")
                    case .denied:
                        print("Denied Tracking Permission")
                    case .notDetermined:
                        print("Not Determined Tracking Permission")
                    case .restricted:
                        print("Restricted Tracking Permission")
                    @unknown default:
                        print("Default value Trackin Permission")
                }

                print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)")

                DispatchQueue.main.async { [self] in
                    // Tracking authorization completed.
                    // Start loading ads here.
                    requestContentFromPlaybackService()
                }
            }
        } else {
            requestContentFromPlaybackService()
        }
    }

    fileprivate func resumeAdAfterForeground() {

        // When the app goes to the background, the Google IMA library will
        // pause the ad.
        // This code demonstrates how you would resume the ad when entering
        // the foreground.
        notificationReceipt = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                     object: nil,
                                                                     queue: nil) {
            [weak self] (notificatin: Notification) in
            guard let self,
                  let playbackController else {
                return
            }

            if adIsPlaying && !isBrowserOpen {
                playbackController.resumeAd()
            }
        }
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                    jsonResponse: Any?,
                    error: Error?) in
            guard let video,
                  let playbackController else {
                if let error {
                    print("ViewController - Error retrieving video: \(error.localizedDescription)")
                }

                return
            }

#if targetEnvironment(simulator)
            if video.usesFairPlay {
                // FairPlay doesn't work when we're running in a simulator,
                // so put up an alert.
                let alert = UIAlertController(title: "FairPlay Warning",
                                              message: """
                                               FairPlay only works on actual \
                                               iOS or tvOS devices.\n
                                               You will not be able to view \
                                               any FairPlay content in the \
                                               iOS or tvOS simulator.
                                               """,
                                              preferredStyle: .alert)

                alert.addAction(.init(title: "OK", style: .default))

                DispatchQueue.main.async { [self] in
                    present(alert, animated: true)
                }

                return
            }
#endif

            let updatedVideo = updateVideo(video)
            playbackController.setVideos([updatedVideo])
        }
    }

    func setupPlaybackController() {
        // NO-OP
    }

    func updateVideo(_ video: BCOVVideo) -> BCOVVideo {
        return video
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension BaseViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }

        // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
        // The events are defined BCOVIMAComponent.h.
        if kBCOVDAILifecycleEventAdsLoaderLoaded == lifecycleEvent.eventType,
           let adsManager = lifecycleEvent.properties[kBCOVDAILifecycleEventPropertyKeyAdsManager] as? IMAAdsManager {
            print("ViewController - Ads loaded.")

            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0
            print("ViewController - IMAAdsManager.volume set to \(String(format: "%0.1f", adsManager.volume))")

        } else if kBCOVDAILifecycleEventAdsManagerDidReceiveAdEvent == lifecycleEvent.eventType,
                  let adEvent = lifecycleEvent.properties["adEvent"] as? IMAAdEvent {
            switch adEvent.type {
                case .STARTED:
                    print("ViewController - Ad Started.")
                    adIsPlaying = true
                case .COMPLETE:
                    print("ViewController - Ad Completed.")
                    adIsPlaying = false
                case .ALL_ADS_COMPLETED:
                    print("ViewController - All ads completed.")
                default:
                    break
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerAdsDelegate

extension BaseViewController: BCOVPlaybackControllerAdsDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didEnter adSequence: BCOVAdSequence!) {
        print("ViewController - Entering ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didExitAdSequence adSequence: BCOVAdSequence!) {
        print("ViewController - Exiting ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didEnter ad: BCOVAd!) {
        print("ViewController - Entering ad")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didExitAd ad: BCOVAd!) {
        print("ViewController - Exiting ad")
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension BaseViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}


// MARK: - BCOVDAIPlaybackSessionDelegate

extension BaseViewController: BCOVDAIPlaybackSessionDelegate {

    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAStreamRequest) {
        // for demo purposes, modify the adTagParameters
        // https://support.google.com/admanager/answer/7320899?hl=en

        adsRequest.adTagParameters = [ "tfcd1": "1" ]

        print("ViewController - IMAStreamRequest.adTagParameters \(String(describing: adsRequest.adTagParameters))")
    }
}


// MARK: - IMALinkOpenerDelegate

extension BaseViewController: IMALinkOpenerDelegate {

    func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
        print("ViewController - linkOpenerDidOpen")
    }

    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        print("ViewController - linkOpenerDidClose")

        // Called when the in-app browser has closed.
        guard let playbackController else { return }
        playbackController.resumeAd()
    }
}
