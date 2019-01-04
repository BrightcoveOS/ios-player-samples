//
//  ViewController.swift
//  BasicOUXtvOSPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveOUX

class ViewController: UIViewController {

    @IBOutlet weak var videoContainer: UIView!
    
    private lazy var playerView: BCOVTVPlayerView? = {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        
        guard let _playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }
        
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        self.videoContainer.addSubview(_playerView)
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ])
        
        return _playerView
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createOUXPlaybackController(viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true

        _playbackController.setVideos([self.OUXVideo] as NSFastEnumeration)
        
        return _playbackController
    }()
    
    private lazy var OUXVideo: BCOVVideo? = {
        let url = URL(string: VideoConfig.url)
        
        let source = BCOVSource(url: url, deliveryMethod: kBCOVSourceDeliveryHLS, properties: nil)
        let properties = [
            "name":VideoConfig.name,
            "thumbnail":VideoConfig.thumbnail,
            "duration":VideoConfig.duration,
            "long_description":VideoConfig.longDescription
        ]
        return BCOVVideo(source: source, cuePoints: BCOVCuePointCollection(array: nil), properties: properties)
    }()
    
    private weak var currentSession: BCOVPlaybackSession?
    
    private var currentTime: TimeInterval?
    private var duration: TimeInterval?
    private var playingAdSequence = false
    private var topDrawerView: UIView?
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [playerView?.controlsView ?? self]
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerView?.playbackController = playbackController
    }


}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        currentSession = session
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
    
    func playbackController(_ controller: BCOVPlaybackController!, didCompletePlaylist playlist: NSFastEnumeration!) {
        print("ViewController Debug - Playlist complete; replaying video")
        playbackController?.setVideos(playlist)
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if let eventType = lifecycleEvent.eventType {
            print("ViewController Debug - lifecycle event type: \(eventType)")
        }
    }
    
}
