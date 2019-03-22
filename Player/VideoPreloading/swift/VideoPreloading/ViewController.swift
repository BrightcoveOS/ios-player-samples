//
//  ViewController.swift
//  VideoPreloading
//
//  Created by Jeremy Blaker on 3/21/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

import UIKit
import BrightcovePlayerSDK

let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerAccountID = "5434391461001"
let kViewControllerPlaylistRefID = "brightcove-native-sdk-plist"

class ViewController: UIViewController, BCOVPlaybackControllerDelegate {
    
    private lazy var playbackService: BCOVPlaybackService = {
       return BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    }()
    
    private lazy var videoPreloadManager: VideoPreloadManager? = {
        guard let playerView = self.playerView else {
            return nil
        }
        return VideoPreloadManager(withPlaybackControllerDelegate: self, andPlayerView: playerView, andShouldAutoPlay: true)
    }()
    
    private lazy var playerView: BCOVPUIPlayerView? = {
        // Set up our player view. Create with a standard VOD layout.
        guard let playerView = BCOVPUIPlayerView(playbackController: nil, options: nil, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return nil
        }
        
        // Install in the container view and match its size.
        self.videoContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
            ])
        return playerView
    }()

    @IBOutlet weak var videoContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestContentFromPlaybackService()
    }
    
    func requestContentFromPlaybackService() {
        playbackService.findPlaylist(withReferenceID: kViewControllerPlaylistRefID, parameters: nil) { [weak self] (playlist: BCOVPlaylist?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            guard let strongSelf = self, let playlist = playlist, let videos = playlist.videos as? [BCOVVideo] else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            strongSelf.videoPreloadManager?.videos = videos
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("Advanced to new session")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        print("Progress: \(progress) seconds")
        videoPreloadManager?.preloadNextVideoIfNeccessary(session)
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd)
        {
            videoPreloadManager?.currentVideoDidCompletePlayback()
        }
    }
}
