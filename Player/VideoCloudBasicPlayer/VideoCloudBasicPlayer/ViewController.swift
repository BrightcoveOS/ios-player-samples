//
//  ViewController.swift
//  VideoCloudBasicPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows the basic setup for playing a single video from
 * Video Cloud: `BCOVPlaybackService.findVideo` retrieves the video and it is
 * played in a `BCOVPUIPlayerView` driven by a playback controller.
 *
 * It also demonstrates several features layered on top of basic playback:
 * AirPlay (external playback plus toggling the route detector), background
 * audio via the `AVAudioSession` category, Picture-in-Picture through the
 * player view delegate, and lock-screen Now Playing info and remote commands
 * via `MPRemoteCommandCenter` / `MPNowPlayingInfoCenter` (see NowPlayingHandler),
 * including artwork and audio-only assets built from Video Cloud custom fields.
 */

import AVKit
import UIKit
import BrightcovePlayerSDK


let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
// Video Asset
let kVideoId = "6140448705001"
// Audio-Only Asset
// let kVideoId = "1732548841120406830"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var muteButton: UIButton!

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
        playbackController.allowsBackgroundAudioPlayback = true
        playbackController.allowsExternalPlayback = true

        playerView.playbackController = playbackController

        nowPlayingHandler = NowPlayingHandler(with: playbackController)

        return playbackController
    }()

    fileprivate var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    fileprivate var nowPlayingHandler: NowPlayingHandler?

    fileprivate weak var currentPlayer: AVPlayer?

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpAudioSession()

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

    fileprivate func setUpAudioSession() {
        do {
            // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
            if let currentPlayer {
                // If the player is muted, then allow mixing.
                // Ensure other apps can have their background audio
                // active when this app is in foreground
                if currentPlayer.isMuted {
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
                } else {
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                }
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            }
        } catch {
            print("ViewController - Error setting AVAudioSession category. Because of this, there may be no sound. \(error)")
        }
    }

    @IBAction
    fileprivate func muteButtonPressed(_ button: UIButton) {
        guard let currentPlayer else { return }

        if currentPlayer.isMuted {
            muteButton.setTitle("Mute AVPlayer", for: .normal)
        } else {
            muteButton.setTitle("Unmute AVPlayer", for: .normal)
        }

        currentPlayer.isMuted = !currentPlayer.isMuted

        setUpAudioSession()
    }

}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        currentPlayer = session.player

        if let routeDetector = playerView?.controlsView?.routeDetector {
            // Enable route detection for AirPlay
            // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
            routeDetector.isRouteDetectionEnabled = true
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }

        if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd,
           let routeDetector = playerView?.controlsView?.routeDetector {
            // Disable route detection for AirPlay
            // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
            routeDetector.isRouteDetectionEnabled = false
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            determinedMediaType mediaType: BCOVSourceMediaType) {
        guard let nowPlayingHandler else { return }
        switch mediaType {
            case .audio:
                nowPlayingHandler.updateNowPlayingInfoForAudioOnly()
            default:
                break
        }
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }

    func picture(_ pictureInPictureController: AVPictureInPictureController!,
                 failedToStartPictureInPictureWithError error: Error!) {
        print("failedToStartPictureInPictureWithError \(error.localizedDescription)")
    }
}
