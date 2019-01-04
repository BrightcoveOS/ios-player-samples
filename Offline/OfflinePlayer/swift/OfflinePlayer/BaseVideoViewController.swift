//
//  BaseVideoViewController.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

class BaseVideoViewController: UIViewController, BCOVPlaybackControllerDelegate {

    @IBOutlet weak var videoContainerView: UIView!
    
    lazy var playerView: BCOVPUIPlayerView? = {
        
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        
        // Create PlayerUI views with normal VOD controls.
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: controlView) else {
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
        
        // Receive delegate method callbacks
        _playerView.delegate = self
        
        return _playerView
    }()
    
    private lazy var authProxy: BCOVFPSBrightcoveAuthProxy? = {
        // Publisher/application IDs not required for Dynamic Delivery
        let _authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)
        
        // You can use the same auth proxy for the offline video manager
        // and the call to create the FairPlay session provider.
        BCOVOfflineVideoManager.shared()?.authProxy = _authProxy
        
        return _authProxy
    }()
    
    var playbackController: BCOVPlaybackController?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playbackController?.pause()
    }
    
    func createNewPlaybackController() {
        // This app shows how to set up your playback controller for playback of FairPlay-protected videos.
        // The playback controller, as well as the download manager will work with either FairPlay-protected
        // videos, or "clear" videos (no DRM protection).
        let sdkManager = BCOVPlayerSDKManager.shared()
        
        // Create the session provider chain
        let options = BCOVBasicSessionProviderOptions()
        options.sourceSelectionPolicy = BCOVBasicSourceSelectionPolicy.sourceSelectionHLS(withScheme: kBCOVSourceURLSchemeHTTPS)
        guard let basicSessionProvider = sdkManager?.createBasicSessionProvider(with: options), let authProxy = self.authProxy else {
            return
        }
        let fairPlaySessionProvider = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate: nil, authorizationProxy: authProxy, upstreamSessionProvider: basicSessionProvider)
        
        // Create the playback controller
        let _playbackController = sdkManager?.createPlaybackController(with: fairPlaySessionProvider, viewStrategy: nil)
        
        // Start playing right away (the default value for autoAdvance is false)
        _playbackController?.isAutoAdvance = true
        _playbackController?.isAutoPlay = true
        
        // Register the delegate method callbacks
        _playbackController?.delegate = self
        
        playerView?.playbackController = _playbackController
        
        playbackController = _playbackController
    }

}

extension BaseVideoViewController: BCOVPUIPlayerViewDelegate {
    
    func playerView(_ playerView: BCOVPUIPlayerView!, willTransitionTo screenMode: BCOVPUIScreenMode) {
        // Hide the tab bar when we go full screen
        tabBarController?.tabBar.isHidden = screenMode == .full
    }
    
}
