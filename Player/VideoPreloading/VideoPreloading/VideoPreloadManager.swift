//
//  VideoPreloadManager.swift
//  VideoPreloading
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


let kPreloadNextSessionThreshold = 0.75 // Translates to 75% of video completed


final class VideoPreloadManager: NSObject {

    fileprivate lazy var playbackControllerAlpha: BCOVPlaybackController? = {
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

        playbackController.delegate = delegate
        playbackController.isAutoAdvance = false

        // Use the shouldAutoPlay value here so the initial video
        // will auto play if the value is YES
        playbackController.isAutoPlay = autoPlayEnabled

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var playbackControllerBravo: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps,
                                                                           viewStrategy: nil)

        playbackController.delegate = delegate
        playbackController.isAutoAdvance = false

        // Second playback controller should not autoplay, we will manually play later
        playbackController.isAutoPlay = false

        return playbackController
    }()

    fileprivate lazy var didBeginPreloadingNextSession: Bool = false
    fileprivate lazy var currentVideoIndex: Int = 0

    fileprivate let autoPlayEnabled: Bool
    fileprivate weak var playerView: BCOVPUIPlayerView?
    fileprivate weak var delegate: BCOVPlaybackControllerDelegate?

    var videos: [BCOVVideo]? {
        didSet {
            // After getting the videos from our playbackService request
            // we want to play the first video on the initial playbackController
            guard let playbackControllerAlpha,
                  let firstVideo = videos?.first else { return }
            playbackControllerAlpha.setVideos([firstVideo])
        }
    }

    init(with playerView: BCOVPUIPlayerView,
         and shouldAutoPlay: Bool,
         and delegate: BCOVPlaybackControllerDelegate?) {

        self.delegate = delegate;
        self.autoPlayEnabled = shouldAutoPlay

        // Keep a weak reference to the BCOVPUIPlayerView object so we can
        // check which playbackController is set and set the next one
        self.playerView = playerView

        super.init()
    }

    func preloadNextVideoIfNeccessary(_ currentSession: BCOVPlaybackSession) {
        if shouldPreloadNextSession(currentSession) {
            preloadNextSession()
        }
    }

    func currentVideoDidCompletePlayback() {
        guard let playerView else { return }
        // Set the next playback controller, which has the preloaded video,
        // as the playerView's playback controller
        playerView.playbackController = nextPlaybackController()

        // Play the video if autoPlay is enabled
        if autoPlayEnabled {
            playerView.playbackController.play()
        }

        // We can now prepare for the next video to be preloaded
        didBeginPreloadingNextSession = false
    }

    fileprivate func shouldPreloadNextSession(_ currentSession: BCOVPlaybackSession) -> Bool {
        guard let player = currentSession.player,
              let currentItem = player.currentItem,
              didBeginPreloadingNextSession == false else {
            return false
        }

        let progressSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(currentItem.duration)

        return (progressSeconds / durationSeconds) >= kPreloadNextSessionThreshold
    }

    fileprivate func preloadNextSession() {
        let nextVideoIndex = currentVideoIndex + 1

        // 1. Verify videos array
        // 2. Get the next playback controller
        // If current is alpha, next will be bravo, and vice versa
        // 3. We don't want to go out-of-bounds!
        guard let videos,
              let nextPlaybackController = nextPlaybackController(),
              nextVideoIndex < videos.count else {
            return
        }

        didBeginPreloadingNextSession = true

        // Get the next video in the array
        let nextVideo = videos[nextVideoIndex]

        // Ensure auto play is disabled
        nextPlaybackController.isAutoPlay = false

        // Set the next video on the next controller to
        // begin preloading
        nextPlaybackController.setVideos([nextVideo])

        // Save the next video's index as the currentVideoIndex
        currentVideoIndex = nextVideoIndex
    }

    fileprivate func nextPlaybackController() -> BCOVPlaybackController? {
        guard let playerView else { return nil }

        if playerView.playbackController.isEqual(playbackControllerAlpha) {
            return playbackControllerBravo
        } else {
            return playbackControllerAlpha
        }
    }
}
