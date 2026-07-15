//
//  ViewController.swift
//  NativeControls
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to play Video Cloud content using Apple's native
 * `AVPlayerViewController` transport controls instead of the Brightcove
 * `BCOVPUIPlayerView`.
 *
 * The `kBCOVAVPlayerViewControllerCompatibilityKey` playback-controller option
 * stops the SDK from creating a redundant `AVPlayerLayer`, since
 * `AVPlayerViewController` already provides one. Each time the controller
 * advances to a new session, that session's `AVPlayer` is handed to the
 * `AVPlayerViewController`.
 */

import AVKit
import UIKit
import BrightcovePlayerSDK


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

    fileprivate lazy var playerViewController: AVPlayerViewController = {
        let playerViewController = AVPlayerViewController()
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewController.view.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerViewController.view)
        addChild(playerViewController)
        playerViewController.didMove(toParent: self)
        return playerViewController
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                   applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps,
                                                                           viewStrategy: nil)

        // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
        // since the AVPlayerViewController already makes one
        playbackController.options = [ kBCOVAVPlayerViewControllerCompatibilityKey: true ]

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()

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
        playerViewController.player = session.player
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }
    }
}
