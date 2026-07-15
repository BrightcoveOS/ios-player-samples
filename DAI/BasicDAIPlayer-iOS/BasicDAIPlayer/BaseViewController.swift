//
//  BaseViewController.swift
//  BasicDAIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
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
    fileprivate var adIsPlaying = false

    fileprivate var statusBarHidden = false {
        didSet {
            if let navigationController {
                navigationController.isNavigationBarHidden = statusBarHidden
            }

            navigationItem.hidesBackButton = statusBarHidden

            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlaybackController()

        resumeAdAfterForeground()

        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
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
                                                                     queue: nil) { [weak self] _ in
            guard let self,
                  let playbackController else {
                return
            }

            if adIsPlaying {
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
                    print("BaseViewController - Error retrieving video: \(error.localizedDescription)")
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
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError {
            // Report any errors that may have occurred with playback.
            print("BaseViewController - Playback error: \(error.localizedDescription)")
        }

        // Ad events are emitted by the BCOVDAI plugin through lifecycle events.
        // The events are defined in BCOVDAIComponent.h.
        if kBCOVDAILifecycleEventAdsLoaderLoaded == lifecycleEvent.eventType,
           let adsManager = lifecycleEvent.properties[kBCOVDAILifecycleEventPropertyKeyAdsManager] as? IMAAdsManager {
            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0
            print("BaseViewController - IMAAdsManager.volume set to \(String(format: "%0.1f", adsManager.volume))")

        } else if kBCOVDAILifecycleEventAdsManagerDidReceiveAdEvent == lifecycleEvent.eventType,
                  let adEvent = lifecycleEvent.properties[kBCOVDAILifecycleEventPropertyKeyAdEvent] as? IMAAdEvent {
            switch adEvent.type {
                case .STARTED:
                    adIsPlaying = true
                case .COMPLETE:
                    adIsPlaying = false
                default:
                    break
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerAdsDelegate

extension BaseViewController: BCOVPlaybackControllerAdsDelegate {

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAdSequence adSequence: BCOVAdSequence) {
        print("ViewController - Entering ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAdSequence adSequence: BCOVAdSequence) {
        print("ViewController - Exiting ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAd ad: BCOVAd) {
        print("ViewController - Entering ad")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAd ad: BCOVAd) {
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

        adsRequest.adTagParameters = [ "tfcd": "0" ]
    }
}


// MARK: - IMALinkOpenerDelegate

extension BaseViewController: IMALinkOpenerDelegate {

    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        // Called when the in-app browser has closed.
        guard let playbackController else { return }
        playbackController.resumeAd()
    }
}
