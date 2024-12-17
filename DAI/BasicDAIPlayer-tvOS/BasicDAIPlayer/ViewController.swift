//
//  ViewController.swift
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

final class ViewController: UIViewController {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVTVPlayerView? = {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true

        guard let playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = view.bounds
        view.addSubview(playerView)

        return playerView
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {

        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode!

        let adsRenderingSettings = IMAAdsRenderingSettings()

        let adsRequestPolicy = BCOVDAIAdsRequestPolicy.videoProperties();

        let daiSessionProvider = sdkManager.createDAISessionProvider(with: imaSettings,
                                                                     adsRenderingSettings: adsRenderingSettings,
                                                                     adsRequestPolicy: adsRequestPolicy,
                                                                     adContainer: playerView!.contentOverlayView,
                                                                     viewController: self,
                                                                     companionSlots: nil,
                                                                     upstreamSessionProvider: fps)

        guard let playerView else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: daiSessionProvider,
                                                                     viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoPlay = true
        playbackController.isAutoAdvance = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestTrackingAuthorization),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [playerView?.controlsView ?? self]
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

        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                    jsonResponse: Any?,
                    error: Error?) in

            if let video,
               let playbackController {

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

                let updatedVideo = video.update { (mutableVideo: BCOVMutableVideo?) in
                    guard let mutableVideo = mutableVideo else {
                        return
                    }

                    var updatedProperties = mutableVideo.properties
                    updatedProperties[kBCOVDAIVideoPropertiesKeySourceId] = kGoogleDAISourceId
                    updatedProperties[kBCOVDAIVideoPropertiesKeyVideoId] = kGoogleDAIVideoId

                    mutableVideo.properties = updatedProperties
                }

                playbackController.setVideos([updatedVideo])
            }
            else {
                print("ViewController Debug - Error retrieving video")
            }
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
                case .COMPLETE:
                    print("ViewController - Ad Completed.")
                case .ALL_ADS_COMPLETED:
                    print("ViewController - All ads completed.")
                default:
                    break
            }
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
