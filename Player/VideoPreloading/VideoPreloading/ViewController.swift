//
//  ViewController.swift
//  VideoPreloading
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to seamlessly advance between videos by preloading
 * the next video while the current one is still playing ("double buffering").
 *
 * Two `BCOVPlaybackController`s share a single `BCOVPUIPlayerView`. While the
 * current controller plays, `VideoPreloadManager` loads the upcoming video into
 * the other controller so it is ready to display the moment playback ends.
 * Preloading starts once the current video passes the 75% progress threshold
 * (`kPreloadNextSessionThreshold`), reported through `-didProgressTo`. Because
 * auto-advance is disabled, the manager swaps the player view's controller on
 * the playback-end lifecycle event.
 *
 * The playlist is fetched by reference id with `-findPlaylistWithConfiguration:`.
 */

import UIKit
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kPlaylistRefId = "brightcove-native-sdk-plist"


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

    fileprivate var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }

    fileprivate lazy var videoPreloadManager: VideoPreloadManager? = {
        guard let playerView else { return nil }

        return VideoPreloadManager(with: playerView, and: true, and: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        requestContentFromPlaybackService()
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetReferenceID: kPlaylistRefId]
        playbackService.findPlaylist(withConfiguration: configuration,
                                     queryParameters: nil) {
            [weak self] (playlist: BCOVPlaylist?,
                         json: Any?,
                         error: Error?) in

            guard let self,
                  let videoPreloadManager,
                  let playlist else {
                if let error {
                    print("ViewController - Error retrieving video playlist: \(error.localizedDescription)")
                }

                return
            }

            let videos = playlist.videos

#if targetEnvironment(simulator)
            videoPreloadManager.videos = videos.filter({ !$0.usesFairPlay })
#else
            videoPreloadManager.videos = videos
#endif
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if kBCOVPlaybackSessionLifecycleEventEnd == lifecycleEvent.eventType,
           let videoPreloadManager {
            videoPreloadManager.currentVideoDidCompletePlayback()
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didProgressTo progress: TimeInterval) {
        if let videoPreloadManager {
            videoPreloadManager.preloadNextVideoIfNecessary(session)
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
