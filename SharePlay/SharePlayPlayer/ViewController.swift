//
//  ViewController.swift
//  SharePlayPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to play a Video Cloud video together with remote
 * participants using SharePlay.
 *
 * `WatchTogether` is the `GroupActivity` shared with the group. When the user
 * starts SharePlay, `WatchTogetherWrapper.activateNewActivity(withVideo:withSource:)`
 * advertises it; the wrapper then listens for the resulting `GroupSession`,
 * joins it, and hands the video's source URL to every participant so each
 * device plays the same content.
 *
 * Synchronized playback is driven by AVPlayer's playback coordinator:
 * `WatchTogetherWrapper` registers as a `BCOVPlaybackSessionConsumer` to obtain
 * the session's `AVPlayer`, then calls
 * `player.playbackCoordinator.coordinateWithSession(_:)` so play, pause, and
 * seek stay in sync across the group.
 */

import UIKit
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var playWithSharePlayButton: UIButton!
    @IBOutlet fileprivate weak var playLocallyButton: UIButton!
    @IBOutlet fileprivate weak var endSharePlayButton: UIButton!
    @IBOutlet fileprivate weak var groupSessionLabel: UILabel!

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true

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

        return playbackController
    }()

    fileprivate lazy var sourceSelectionPolicy: BCOVBasicSessionProviderSourceSelectionPolicy = {
        return BCOVBasicSourceSelectionPolicy.sourceSelectionHLS(withScheme: BCOVSource.URLSchemeHTTPS)
    }()

    fileprivate lazy var watchTogether: WatchTogetherWrapper = {

        let watchTogether = WatchTogetherWrapper()
        watchTogether.delegate = self

        guard let playbackController else {
            return watchTogether
        }

        watchTogether.playbackController = playbackController
        playbackController.add(watchTogether)

        return watchTogether
    }()

    fileprivate var playWithSharePlay = false

    fileprivate var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        endSharePlayButton.isEnabled = false
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                    jsonResponse: Any?,
                    error: Error?) in

            guard let video else {
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

            if playWithSharePlay {
                if let source = sourceSelectionPolicy(video) {
                    watchTogether.activateNewActivity(withVideo: video,
                                                      withSource: source)
                }
            } else {
                if let playbackController {
                    playbackController.setVideos([video])
                }
            }
        }
    }

    fileprivate func updateSessionLabel(withStatus status: String) {
        groupSessionLabel.text = "Group Session: \(status)"
    }

    @IBAction
    fileprivate func playLocallyButtonPressed(_ button: UIButton) {
        // End the existing SharePlay activity if needed
        watchTogether.endSharePlay()

        playWithSharePlay = false
        requestContentFromPlaybackService()
    }

    @IBAction
    fileprivate func playWithSharePlayButtonPressed(_ button: UIButton) {
        playWithSharePlay = true
        requestContentFromPlaybackService()
    }

    @IBAction
    fileprivate func endSharePlayButtonPressed(_ button: UIButton) {
        watchTogether.endSharePlay()
    }
}


// MARK: - WatchTogetherWrapperDelegate

extension ViewController: WatchTogetherWrapperDelegate {

    func groupSessionWasJoined() {
        DispatchQueue.main.async { [self] in
            updateSessionLabel(withStatus: "Joined")
            endSharePlayButton.isEnabled = true
        }
    }

    func groupSessionWasInvalidated() {
        DispatchQueue.main.async { [self] in
            updateSessionLabel(withStatus: "Inactive")
            endSharePlayButton.isEnabled = false
        }
    }

    func activityWasDisabled() {
        DispatchQueue.main.async { [self] in
            updateSessionLabel(withStatus: "Inactive")
            endSharePlayButton.isEnabled = false
        }
    }

    func activityWasActivated() {
        print("ViewController - Activity did Activate")
    }

    func activityFailedActivation() {
        print("ViewController - Activity Failed to Activate")
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError {
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
