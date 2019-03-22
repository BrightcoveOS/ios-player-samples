//
//  VideoPreloadManager.swift
//  VideoPreloading
//
//  Created by Jeremy Blaker on 3/21/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

let kPreloadNextSessionThreshold = 0.75 // Translates to 75% of video completed

class VideoPreloadManager: NSObject {
    
    private lazy var playbackControllerAlpha: BCOVPlaybackController? = {
        return BCOVPlayerSDKManager.shared()?.createPlaybackController()
    }()
    
    private lazy var playbackControllerBravo: BCOVPlaybackController? = {
        return BCOVPlayerSDKManager.shared()?.createPlaybackController()
    }()
    
    private let autoPlayEnabled: Bool
    private var didBeginPreloadingNextSession: Bool = false
    private var currentVideoIndex: Int = 0
    
    private weak var playerView: BCOVPUIPlayerView?
    
    var videos: [BCOVVideo]? {
        didSet {
            // After getting the videos from our playbackService request
            // we want to play the first video on the initial playbackController
            guard let firstVideo = videos?.first else {
                return
            }
            playbackControllerAlpha?.setVideos([firstVideo] as NSFastEnumeration)
        }
    }
    
    init(withPlaybackControllerDelegate delegate: BCOVPlaybackControllerDelegate, andPlayerView playerView: BCOVPUIPlayerView, andShouldAutoPlay shouldAutoPlay: Bool) {
        
        self.autoPlayEnabled = shouldAutoPlay
        
        // Keep a weak reference to the BCOVPUIPlayerView object so we can
        // check which playbackController is set and set the next one
        self.playerView = playerView
        
        super.init()
        
        // Use the shouldAutoPlay value here so the initial video
        // will auto play if the value is YES
        self.playbackControllerAlpha?.isAutoPlay = shouldAutoPlay
        self.playbackControllerAlpha?.isAutoAdvance = false
        self.playbackControllerAlpha?.delegate = delegate
        
        // Second playback controller should not autoplay, we will manually play later
        self.playbackControllerBravo?.isAutoPlay = false
        self.playbackControllerBravo?.isAutoAdvance = false
        self.playbackControllerBravo?.delegate = delegate
        
        self.playerView?.playbackController = self.playbackControllerAlpha
    }
    
    private func shouldPreloadNextSession(_ currentSession: BCOVPlaybackSession) -> Bool {
        guard let player = currentSession.player, let currentItem = player.currentItem, didBeginPreloadingNextSession == false else {
            return false
        }
        let progressSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(currentItem.duration)
        return ((progressSeconds / durationSeconds) >= kPreloadNextSessionThreshold)
    }
    
    private func preloadNextSession() {
        let nextVideoIndex = currentVideoIndex + 1
        
        // 1. Verify videos array
        // 2. Get the next playback controller
        // If current is alpha, next will be bravo, and vice versa
        // 3. We don't want to go out-of-bounds!
        guard let videos = videos, let nextPlaybackController = nextPlaybackController(), nextVideoIndex < videos.count else {
            return
        }
        
        didBeginPreloadingNextSession = true
        
        // Get the next video in the array
        let nextVideo = videos[nextVideoIndex]
        
        // Ensure auto play is disabled
        nextPlaybackController.isAutoPlay = false
        
        // Set the next video on the next controller to
        // begin preloading
        nextPlaybackController.setVideos([nextVideo] as NSFastEnumeration)
        
        // Save the next video's index as the currentVideoIndex
        currentVideoIndex = nextVideoIndex
    }
    
    private func nextPlaybackController() -> BCOVPlaybackController? {
        guard let playerView = playerView else {
            return nil
        }
        
        if (playerView.playbackController.isEqual(playbackControllerAlpha)) {
            return playbackControllerBravo
        } else {
            return playbackControllerAlpha
        }
    }
    
    func preloadNextVideoIfNeccessary(_ currentSession: BCOVPlaybackSession) {
        if (shouldPreloadNextSession(currentSession)) {
            preloadNextSession()
        }
    }
    
    func currentVideoDidCompletePlayback() {
        guard let playerView = playerView else {
            return
        }
        // Set the next playback controller, which has the preloaded video,
        // as the playerView's playback controller
        playerView.playbackController = nextPlaybackController()
        // Play the video if autoPlay is enabled
        if (autoPlayEnabled) {
            playerView.playbackController.play()
        }
        // We can now prepare for the next video to be preloaded
        didBeginPreloadingNextSession = false
    }

}
