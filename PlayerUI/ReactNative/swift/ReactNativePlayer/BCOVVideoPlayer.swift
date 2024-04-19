//
//  BCOVVideoPlayer.swift
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit
import React
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"


final class BCOVVideoPlayer: UIView {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
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

        guard let playbackController = sdkManager.createPlaybackController(with: fps,
                                                                           viewStrategy: nil) else {
            return nil
        }

        playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: true]

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()

    fileprivate lazy var avpvc: AVPlayerViewController = {
        let avpvc = AVPlayerViewController()
        avpvc.showsPlaybackControls = false
        return avpvc
    }()

    @objc fileprivate(set) var onReady: RCTDirectEventBlock?

    @objc fileprivate(set) var onProgress: RCTDirectEventBlock?

    init() {
        super.init(frame: UIScreen.main.bounds)

        addSubview(avpvc.view)
        requestContentFromPlaybackService()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
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
            if video.usesFairPlay,
               let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let window = appDelegate.window,
               let rootViewController = window.rootViewController {
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

                DispatchQueue.main.async {
                    rootViewController.present(alert, animated: true)
                }

                return
            }
#endif

            playbackController.setVideos([video] as NSFastEnumeration)
        }
    }

    @objc
    func playPause(_ isPlaying: Bool) {
        guard let playbackController else { return }
        if isPlaying {
            playbackController.pause()
        } else {
            playbackController.play()
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension BCOVVideoPlayer: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")

        avpvc.player = session.player

        guard let onReady,
              let duration = session?.video.properties["duration"] as? TimeInterval else {
            return
        }

        onReady([ "duration": duration,
                  "isAutoPlay": NSNumber(value: controller.isAutoPlay) ])
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

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didProgressTo progress: TimeInterval) {

        guard let onProgress,
              progress.isFinite else { return }

        onProgress([ "progress": NSNumber(value: progress) ])
    }
}
