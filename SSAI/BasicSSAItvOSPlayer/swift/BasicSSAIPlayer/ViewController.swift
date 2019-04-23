//
//  ViewController.swift
//  BasicSSAIPlayer
//
//  Created by Jeremy Blaker on 3/18/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveSSAI

// ** Customize these values with your own account information **
struct Constants {
    static let AccountID = "5434391461001"
    static let PlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let VideoId = "5702141808001"
    static let AdConfigId = "0e0bbcd1-bba0-45bf-a986-1288e5f9fc85"
}

class ViewController: UIViewController {
    @IBOutlet weak var videoContainerView: UIView!
    
    private lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: Constants.AccountID, policyKey: Constants.PlaybackServicePolicyKey, baseURLStr: "https://edge.api.brightcove.com/playback/v1")
        return BCOVPlaybackService(requestFactory: factory)
    }()
    
    private lazy var fairplayAuthProxy: BCOVFPSBrightcoveAuthProxy? = {
        guard let _authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil) else {
            return nil
        }
        return _authProxy
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let manager = BCOVPlayerSDKManager.shared(), let fairplayAuthProxy = fairplayAuthProxy else {
            return nil
        }
        
        let fairplaySessionProvider = manager.createFairPlaySessionProvider(with: fairplayAuthProxy, upstreamSessionProvider: nil)
        let ssaiSessionProvider = manager.createSSAISessionProvider(withUpstreamSessionProvider: fairplaySessionProvider)
        
        guard let _playbackController = manager.createPlaybackController(with: ssaiSessionProvider, viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
    private lazy var playerView: BCOVTVPlayerView? = {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        //options.hideControlsInterval = 3000
        //options.hideControlsAnimationDuration = 0.2
        
        // Create PlayerUI views with normal VOD controls.
        guard let _playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }
        
        // Add to parent view
        self.videoContainerView.addSubview(_playerView)
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
            ])
        
        return _playerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestContentFromPlaybackService()
    }
    
    private func requestContentFromPlaybackService() {
        let queryParameters = [kBCOVPlaybackServiceParamaterKeyAdConfigId: Constants.AdConfigId]

        playbackService.findVideo(withVideoID: Constants.VideoId, parameters: queryParameters) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            guard let _video = video else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self?.playbackController?.setVideos([_video] as NSFastEnumeration)
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        guard let _playerView = self.playerView else {
            return []
        }
        return [_playerView]
    }
    
    override var preferredFocusedView: UIView? {
        return self.playerView
    }
}

// MARK: - BCOVPlaybackControllerDelegate
extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
}

// MARK: - BCOVPlaybackControllerAdsDelegate
extension ViewController: BCOVPlaybackControllerAdsDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
        print("ViewController Debug - Entering ad sequence")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
        print("ViewController Debug - Exiting ad sequence")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter ad: BCOVAd!) {
        print("ViewController Debug - Entering ad")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAd ad: BCOVAd!) {
        print("ViewController Debug - Exiting ad")
    }
}


