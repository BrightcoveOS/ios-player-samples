//
//  ViewController.swift
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import BrightcovePulse


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"

// Replace with your own Pulse Host
let kPulseHost = "https://bc-test.videoplaza.tv"


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

    fileprivate lazy var  playbackController: BCOVPlaybackController? = {
        /**
         *  Initialize the Brightcove Pulse Plugin.
         *  Host:
         *      The host is derived from the "sub-domain” found in the Pulse UI and is formulated
         *      like this: `https://[sub-domain].videoplaza.tv`
         *  Device Container (kBCOVPulseOptionPulseDeviceContainerKey):
         *      The device container in Pulse is used for targeting and reporting purposes.
         *      This device container attribute is only used if you want to override the Pulse
         *      device detection algorithm on the Pulse ad server. This should only be set if normal
         *      device detection does not work and only after consulting our personnel.
         *      An incorrect device container value can result in no ads being served
         *      or incorrect ad delivery and reports.
         *  Persistent Id (kBCOVPulseOptionPulsePersistentIdKey):
         *      The persistent identifier is used to identify the end user and is the
         *      basis for frequency capping, uniqueness, DMP targeting information and
         *      more. Use Apple's advertising identifier (IDFA), or your own unique
         *      user identifier here.
         *
         *  Refer to:
         *  https://docs.invidi.com/r/INVIDI-Pulse-Documentation/Pulse-SDKs-parameter-reference
         */

        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
        let contentMetadata = OOContentMetadata()
        contentMetadata.tags = [ "standard-linears" ]

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
        let requestSettings = OORequestSettings()
        requestSettings.linearPlaybackPositions = [ 45, 90, 135]

        let persistentId = ASIdentifierManager.shared().advertisingIdentifier.uuidString

        let pulsePlaybackSessionOptions = [
            kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
            kBCOVPulseOptionPulsePersistentIdKey: persistentId]

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView,
              let contentOverlayView = playerView.contentOverlayView,
              let pulseSessionProvider = sdkManager.createPulseSessionProvider(withPulseHost: kPulseHost,
                                                                               contentMetadata: contentMetadata,
                                                                               requestSettings: requestSettings,
                                                                               adContainer: contentOverlayView,
                                                                               companionSlots: nil,
                                                                               upstreamSessionProvider: fps,
                                                                               options: pulsePlaybackSessionOptions) else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: pulseSessionProvider, viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsBackgroundAudioPlayback = true

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
