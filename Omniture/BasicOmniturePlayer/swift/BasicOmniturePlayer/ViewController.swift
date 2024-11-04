//
//  ViewController.swift
//  BasicOmniturePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK
import BrightcoveAMC


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!

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
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps,
                                                                     viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        // Use Adobe Video Media Heartbeat v2.0 analytics
        playbackController.add(videoHeartbeatSessionConsumer)
        // OR use Adobe media analytics
        //playbackController.add(mediaAnalyticsSessionConsumer)

        return playbackController
    }()

    fileprivate lazy var videoHeartbeatSessionConsumer: BCOVAMCSessionConsumer = {
        let videoHeartbeatConfigurationPolicy: BCOVAMCVideoHeartbeatConfigurationPolicy = {
            (session: BCOVPlaybackSession?) in

            let configData = ADBMediaHeartbeatConfig()

            configData.trackingServer = "ovppartners.hb.omtrdc.net"
            configData.channel = "test-channel"
            configData.appVersion = "1.0.0"
            configData.ovp = "Brightcove"
            configData.playerName = "BasicOmniturePlayer"
            configData.ssl = false

            // NOTE: remove this in production code.
            configData.debugLogging = true

            return configData

        }

        let heartbeatPolicy = BCOVAMCAnalyticsPolicy(heartbeatConfigurationPolicy: videoHeartbeatConfigurationPolicy)

        return BCOVAMCSessionConsumer.heartbeatAnalyticsConsumer(with: heartbeatPolicy,
                                                                 delegate: self)
    }()

    fileprivate lazy var mediaAnalyticsSessionConsumer: BCOVAMCSessionConsumer = {
        let mediaSettingPolicy: BCOVAMCMediaSettingPolicy = {
            (session: BCOVPlaybackSession?) in
            
            // You can set video length to 0. Omniture plugin will update it later for you.
            let settings = ADBMobile.mediaCreateSettings(withName: "BCOVOmniturePlayerMediaSettings",
                                                         length: 0,
                                                         playerName: "BasicOmmiturePlayer",
                                                         playerID: "BasicOmniturePlayer")

            // Adobe media analytics setting customization
            // settings.milestones = @"25,50,75"

            return settings
        }

        let mediaPolicy = BCOVAMCAnalyticsPolicy(mediaSettingsPolicy: mediaSettingPolicy)

        return BCOVAMCSessionConsumer.mediaAnalyticsConsumer(with: mediaPolicy,
                                                             delegate: self)
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

        requestContentFromPlaybackService()
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


// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}


// MARK: - BCOVAMCSessionConsumerHeartbeatDelegate

extension ViewController: BCOVAMCSessionConsumerHeartbeatDelegate {

    func heartbeatVideoUnloaded(on session: BCOVPlaybackSession!) {
        print("ViewController - heartbeatVideoUnloadedOnSession")
    }
}


// MARK: - BCOVAMCSessionConsumerMediaDelegate

extension ViewController: BCOVAMCSessionConsumerMediaDelegate {

    func media(on session: BCOVPlaybackSession!,
               mediaState: ADBMediaState!) {
        guard let mediaEvent = mediaState.mediaEvent else {
            return
        }

        print("ViewController - mediaEvent = \(mediaEvent)")

        if  mediaEvent == "MILESTONE" {
            print("ViewController - milestone = \(mediaState.milestone)")
        }
    }
}
