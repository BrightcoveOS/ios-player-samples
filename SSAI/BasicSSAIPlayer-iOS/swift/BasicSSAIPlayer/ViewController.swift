//
//  ViewController.swift
//  BasicSSAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import BrightcoveSSAI
// import OMSDK_Brightcove


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "5702141808001"
let kAdConfigId = "0e0bbcd1-bba0-45bf-a986-1288e5f9fc85"
let kVMAPURL = "https://sdks.support.brightcove.com/assets/ads/ssai/sample-vmap.xml"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var companionSlotContainerView: UIView!

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
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

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        guard let sdkManager = BCOVPlayerSDKManager.sharedManager(),
              let authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
                                                         applicationId: nil) else {
            return nil
        }

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        // To take the advantage of using IAB Open Measurement,
        // the SSAI Plugin for iOS provides a new signature:
        // BCOVPlayerSDKManager.sharedManager().createSSAISessionProvider(withUpstreamSessionProvider:, omidPartner:)
        //
        // let ssaiSessionProvider = sdkManager.createSSAISessionProvider(withUpstreamSessionProvider: fps,
        //                                                                omidPartner: "yourOmidPartner")
        //
        // The `omidPartner` string identifies the integration.
        // The value can not be empty or nil, if partner is not available, use "unknown".
        // The IAB Tech Lab will assign a unique partner name to you at the time of integration,
        // so this is the value you should use here.

        let ssaiSessionProvider = sdkManager.createSSAISessionProvider(withUpstreamSessionProvider: fps)

        guard let playerView,
              let playbackController = sdkManager.createPlaybackController(with: ssaiSessionProvider,
                                                                           viewStrategy: nil) else {
            return nil
        }

        // Create a companion slot.
        let companionSlot = BCOVSSAICompanionSlot(view: companionSlotContainerView,
                                                  width: 300,
                                                  height: 250)

        // In order to display an ad progress banner on the top of the view,
        // we create this display container. This object is also responsible
        // for populating the companion slots.
        let adComponentDisplayContainer = BCOVSSAIAdComponentDisplayContainer(companionSlots: [companionSlot])

        // In order for the ad display container to receive ad information,
        // we add it as a session consumer.
        playbackController.add(adComponentDisplayContainer)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    // When this value is set to YES the playback service
    // will be bypassed and a hard-coded VMAP URL will be used
    // to create a BCOVVideo instead
    fileprivate let useVMAPURL = false

    fileprivate lazy var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestTrackingAuthorization),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc
    fileprivate func requestTrackingAuthorization() {
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
                    if useVMAPURL {
                        if let playbackController,
                           let url = URL(string: kVMAPURL) {
                            let video = BCOVVideo(url: url)

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

                            playbackController.setVideos([video] as NSFastEnumeration)
                        }
                    } else {
                        requestContentFromPlaybackService()
                    }
                }

            }
        } else {
            if useVMAPURL {
                if let playbackController,
                   let url = URL(string: kVMAPURL) {
                    let video = BCOVVideo(url: url)
                    playbackController.setVideos([video] as NSFastEnumeration)
                }
            } else {
                requestContentFromPlaybackService()
            }
        }

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId]
        let queryParameters = [kBCOVPlaybackServiceParamaterKeyAdConfigId: kAdConfigId]

        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: queryParameters) {
            [playbackController] (video: BCOVVideo?,
                                  jsonResponse: [AnyHashable: Any]?,
                                  error: Error?) in
            guard let playbackController,
                  let video else {
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

            playbackController.setVideos([video] as NSFastEnumeration)
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

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
    }
}


// MARK: - BCOVPlaybackControllerAdsDelegate

extension ViewController: BCOVPlaybackControllerAdsDelegate {

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

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}
