//
//  BCOVVideoPlayer.swift
//  PlayerReactNative
//
//  Created by Carlos Ceja.
//

import AVFoundation
import AVKit
import Foundation
import UIKit

import BrightcovePlayerSDK
import React

class BCOVVideoPlayer: UIView {
    
    @objc var options: NSDictionary? {
        didSet {
            let parsedData = options as! [String: Any]
            
            let playbackControllerArgs = parsedData["playbackController"] as! [String: Any]
            let autoPlay = playbackControllerArgs["autoPlay"] as! Bool
            let autoAdvance = playbackControllerArgs["autoAdvance"] as! Bool
            
            self.playbackController = self.manager.createPlaybackController()!
            self.playbackController.delegate = self
            self.playbackController.isAutoPlay = autoPlay
            self.playbackController.isAutoAdvance = autoAdvance
            self.playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: true]
            
            let playbackServiceArgs = parsedData["playbackService"] as! [String: Any]
            let accountId = playbackServiceArgs["accountId"] as! String
            let policyKey = playbackServiceArgs["policyKey"] as! String
            self.playbackService = BCOVPlaybackService(accountId: accountId, policyKey: policyKey)
            
            let videoId = playbackServiceArgs["videoId"] as! String
            let authToken = playbackServiceArgs["authToken"] as? String
            let parameters = playbackServiceArgs["parameters"] as? [AnyHashable : Any]
            
            var configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:videoId]
            if authToken != nil {
                configuration[kBCOVPlaybackServiceConfigurationKeyAuthToken] = authToken
            }
            playbackService?.findVideo(withConfiguration: configuration, queryParameters: parameters, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
                if let video = video {
                    self?.playbackController.setVideos([video] as NSFastEnumeration)
                }
            })
        }
    }
    
    @objc var onReady: RCTDirectEventBlock?
    
    @objc var onProgress: RCTDirectEventBlock?
    
    @objc var eventDispatcher: RCTEventDispatcher!
    
    lazy private var player: AVPlayer = {
        var _player = AVPlayer()
        return _player
    }()
    
    lazy private var avpvc: AVPlayerViewController = {
        var _avpvc = AVPlayerViewController()
        _avpvc.player = self.player
        _avpvc.showsPlaybackControls = false
        return _avpvc
    }()
    
    lazy private var manager: BCOVPlayerSDKManager = {
        let _manager = BCOVPlayerSDKManager.shared()!
        return _manager
    }()
    
    private var playbackService: BCOVPlaybackService!
    private var playbackController: BCOVPlaybackController!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.avpvc.view)
    }
    
    func setEventDispatcher(_ eventDispatcher: RCTEventDispatcher) {
        self.eventDispatcher = eventDispatcher
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func playPause(_ isPlaying: Bool) {
        if isPlaying {
            self.player.pause()
        }
        else {
            self.player.play()
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension BCOVVideoPlayer: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        
        self.player = session.player
        self.avpvc.player = session.player
        
        if (self.onReady != nil) {
            let duration = session?.video.properties["duration"] as! NSNumber
            self.onReady?(["duration": duration])
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        
        if (self.onProgress != nil && !progress.isInfinite) {
            self.onProgress?(["progress": NSNumber(value: progress)])
        }
    }
}
