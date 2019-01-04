//
//  ViewController.swift
//  BasicOmniturePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK
import BrightcoveAMC

struct ConfigConstants {
    static let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    static let AccountID = "3636334163001"
    static let VideoID = "3666678807001"
}

class ViewController: UIViewController {
    
    @IBOutlet weak var videoContainerView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private lazy var playerView: BCOVPUIPlayerView? = {
        // Create PlayerUI views with normal VOD controls.
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: nil, controlsView: controlView) else {
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
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        
        // Use Adobe Video Media Heartbeat v2.0 analytics
        _playbackController.add(self.videoHeartbeatSessionConsumer)
        // OR use Adobe media analytics
        //_playbackController.add(self.mediaAnalyticsSessionConsumer)
        
        return _playbackController
    }()
    
    private lazy var videoHeartbeatSessionConsumer: BCOVAMCSessionConsumer = {

        var videoHeartbeatConfigurationPolicy: BCOVAMCVideoHeartbeatConfigurationPolicy = {
            (session: BCOVPlaybackSession?) in
            
            let configData = ADBMediaHeartbeatConfig()
            
            configData.trackingServer = "ovppartners.hb.omtrdc.net"
            configData.channel = "test-channel"
            configData.appVersion = "1.0.0"
            configData.ovp = "Brightcove"
            configData.playerName = "BasicOmniturePlayer"
            configData.ssl = false
            
            // NOTE: remove this in production code.
            configData.debugLogging = true
            
            return configData
            
        }
        
        let heartbeatPolicy = BCOVAMCAnalyticsPolicy(heartbeatConfigurationPolicy: videoHeartbeatConfigurationPolicy)
        
        return BCOVAMCSessionConsumer.heartbeatAnalyticsConsumer(with: heartbeatPolicy, delegate: self)
        
    }()
    
    private lazy var mediaAnalyticsSessionConsumer: BCOVAMCSessionConsumer = {
       
        let mediaSettingPolicy: BCOVAMCMediaSettingPolicy = {
            (session: BCOVPlaybackSession?) in
            
            // You can set video length to 0. Omniture plugin will update it later for you.
            let settings = ADBMobile.mediaCreateSettings(withName: "BCOVOmniturePlayerMediaSettings", length: 0, playerName: "BasicOmmiturePlayer", playerID: "BasicOmniturePlayer")
            
            // Adobe media analytics setting customization
            // settings.milestones = @"25,50,75";
            
            return settings
        }
        
        let mediaPolicy = BCOVAMCAnalyticsPolicy(mediaSettingsPolicy: mediaSettingPolicy)
        
        return BCOVAMCSessionConsumer.mediaAnalyticsConsumer(with: mediaPolicy, delegate: self)
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        return BCOVPlaybackService(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PlaybackServicePolicyKey)
    }()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerView?.playbackController = playbackController
        requestContentFromPlaybackService()
    }

    private func requestContentFromPlaybackService() {
        
        playbackService.findVideo(withVideoID: ConfigConstants.VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            if let video = video {
                self?.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            
            if let error = error {
                print("ViewController Debug - Error retrieving video playlist: \(error.localizedDescription)")
            }
            
        }
        
    }

}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
    
}

// MARK: - BCOVAMCSessionConsumerHeartbeatDelegate

extension ViewController: BCOVAMCSessionConsumerHeartbeatDelegate {
    
    func heartbeatVideoUnloaded(on session: BCOVPlaybackSession!) {
        print("ViewController Debug - heartbeatVideoUnloadedOnSession:")
    }
    
}

// MARK: - BCOVAMCSessionConsumerMeidaDelegate

extension ViewController: BCOVAMCSessionConsumerMeidaDelegate {
    
    func media(on session: BCOVPlaybackSession!, mediaState: ADBMediaState!) {
        guard let mediaEvent = mediaState.mediaEvent else {
            return
        }
        print("mediaEvent = \(mediaEvent)")
        if  mediaEvent == "MILESTONE" {
            print("milestone = \(mediaState.milestone)")
        }
    }
    
}
