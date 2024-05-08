//
//  ViewController.swift
//  VideoPreloading
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

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
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
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

    fileprivate lazy var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
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
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetReferenceID: kPlaylistRefId]
        playbackService.findPlaylist(withConfiguration: configuration,
                                     queryParameters: nil) {
            [self] (playlist: BCOVPlaylist?,
                    json: [AnyHashable:Any]?,
                    error: Error?) in

            guard let videoPreloadManager,
                  let playlist,
                  let videos = playlist.videos as? [BCOVVideo] else {
                if let error {
                    print("ViewController - Error retrieving video playlist: \(error.localizedDescription)")
                }

                return
            }

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
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if kBCOVPlaybackSessionLifecycleEventEnd == lifecycleEvent.eventType,
           let videoPreloadManager {
            videoPreloadManager.currentVideoDidCompletePlayback()
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didProgressTo progress: TimeInterval) {
        print("Progress: \(progress) seconds")

        if let videoPreloadManager {
            videoPreloadManager.preloadNextVideoIfNeccessary(session)
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
