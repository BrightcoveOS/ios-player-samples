//
//  ViewController.swift
//  BasicFreeWheelPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import AdManager
import BrightcoveFW


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"

let kNetworkId = 42015
let kServerURL = "http://demo.v.fwmrm.net"
let kPlayerProfile = "42015:ios_allinone_profile"
let kSiteSectionId = "ios_allinone_demo_site_section"
let kVideoAssetId = "ios_allinone_demo_video"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!

    fileprivate var bcovAdContext: BCOVFWContext?

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
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
        let options = BCOVFWSessionProviderOptions()
        options.cuePointProgressPolicy = BCOVCuePointProgressPolicy(processingCuePoints: .processFinalCuePoint,
                                                                    resumingPlaybackFrom: .fromContentPlayhead,
                                                                    ignoringPreviouslyProcessedCuePoints: true)
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView,
              let fwSessionProvider = sdkManager.createFWSessionProvider(adContextPolicy: adContextPolicy,
                                                                         upstreamSessionProvider: fps,
                                                                         options: options) else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fwSessionProvider, viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var adManager: FWAdManager? = {
        guard let adManager = newAdManager() else {
            return nil
        }

        adManager.setNetworkId(UInt(kNetworkId))

        return adManager
    }()

    fileprivate lazy var adContextPolicy: BCOVFWSessionProviderAdContextPolicy = {
        return { [weak self] video, source, duration in
            // This block will get called before every session is delivered. The source,
            // video, and duration are provided in case you need to use them to
            // customize the these settings.
            // The values below are specific to this sample app, and should be changed
            // appropriately. For information on what values need to be provided,
            // please refer to your FreeWheel documentation or contact your FreeWheel
            // account executive. Basic information is provided below.
            guard let self,
                  let adManager,
                  let adContext = adManager.newContext(),
                  let contentOverlayView = playerView?.contentOverlayView else {
                return nil
            }

            // This is the view where the ads will be rendered.
            adContext.setVideoDisplayBase(contentOverlayView)

            let adRequestConfig = FWRequestConfiguration(serverURL: kServerURL,
                                                         playerProfile: kPlayerProfile,
                                                         playerDimensions: videoContainerView.frame.size)

            adRequestConfig.siteSectionConfiguration = FWSiteSectionConfiguration(siteSectionId: kSiteSectionId,
                                                                                  idType: .custom)

            adRequestConfig.videoAssetConfiguration = FWVideoAssetConfiguration(videoAssetId: kVideoAssetId,
                                                                                idType: .custom,
                                                                                duration: duration,
                                                                                durationType: .exact,
                                                                                autoPlayType:.attended)

            adRequestConfig.add(FWTemporalSlotConfiguration(customId: "preroll",
                                                            adUnit: FWAdUnitPreroll,
                                                            timePosition: 0.0))

            adRequestConfig.add(FWTemporalSlotConfiguration(customId: "midroll60",
                                                            adUnit: FWAdUnitMidroll,
                                                            timePosition: 60.0))

            adRequestConfig.add(FWTemporalSlotConfiguration(customId: "midroll120",
                                                            adUnit: FWAdUnitMidroll,
                                                            timePosition: 120.0))

            adRequestConfig.add(FWTemporalSlotConfiguration(customId: "postroll",
                                                            adUnit: FWAdUnitPostroll,
                                                            timePosition: 0.0))

            // We save the adContext to the class so that we can access outside the
            // block. In this case, we will need to retrieve the companion ad slot.
            let bcovAdContext = BCOVFWContext(adContext: adContext,
                                              requestConfiguration: adRequestConfig)
            self.bcovAdContext = bcovAdContext

            return bcovAdContext
        }
    }()

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
                    requestContentFromPlaybackService()
                }

            }
        } else {
            requestContentFromPlaybackService()
        }

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [playbackController] (video: BCOVVideo?,
                                  jsonResponse: Any?,
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

            playbackController.setVideos([video])
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
