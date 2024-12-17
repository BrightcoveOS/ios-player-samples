//
//  ViewController.swift
//  SLS_IMA-Player
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import GoogleInteractiveMediaAds
import BrightcoveIMA
import BrightcoveSSAI


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "insertyouraccountidhere"
let kPolicyKey = "insertyourpolicykeyhere"
let kVideoId = "insertyourvideoidhere"
let kAdConfigId = "insertyouradconfigidhere"

let kViewControllerVMAPAdTagURL = "insertyouradtaghere"


final class ViewController: UIViewController {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVTVPlayerView? = {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        //options.hideControlsInterval = 3000
        //options.hideControlsAnimationDuration = 0.2

        guard let playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }

        playerView.frame = view.bounds
        view.addSubview(playerView)

        return playerView
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self

        // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vmapAdTagUrl: kViewControllerVMAPAdTagURL)

        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
        // which allows us to modify the IMAAdsRequest object before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView,
              let contentOverlayView = playerView.contentOverlayView,
              let imaSessionProvider = sdkManager.createIMASessionProvider(with: imaSettings,
                                                                           adsRenderingSettings: renderSettings,
                                                                           adsRequestPolicy: adsRequestPolicy,
                                                                           adContainer: contentOverlayView,
                                                                           viewController: self,
                                                                           companionSlots: nil,
                                                                           upstreamSessionProvider: fps,
                                                                           options: imaPlaybackSessionOptions) else {
            return nil
        }

        let ssaiSessionProvider = sdkManager.createSSAISessionProvider(withUpstreamSessionProvider: imaSessionProvider)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: ssaiSessionProvider,
                                                                           viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoPlay = true
        playbackController.isAutoAdvance = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [playerView?.controlsView ?? self]
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
        if #available(tvOS 14.5, *) {
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
        let queryParameters = [BCOVPlaybackService.ParamaterKeyAdConfigId: kAdConfigId]

        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: queryParameters) {
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


// MARK: - BCOVIMAPlaybackSessionDelegate

extension ViewController: BCOVIMAPlaybackSessionDelegate {

    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!,
                                        forPosition position: TimeInterval) {
        // for demo purposes, increase the VAST ad load timeout.
        adsRequest.vastLoadTimeout = 3000.0
        print("ViewController - IMAAdsRequest.vastLoadTimeout set to \(String(format: "%.1f", adsRequest.vastLoadTimeout)) milliseconds.")
    }
}
