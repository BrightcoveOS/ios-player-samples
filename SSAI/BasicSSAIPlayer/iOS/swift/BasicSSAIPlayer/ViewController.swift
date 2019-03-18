//
//  ViewController.swift
//  BasicSSAIPlayer
//
//  Created by Jeremy Blaker on 3/15/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveOUX

// ** Customize these values with your own account information **
struct Constants {
    static let AccountID = ""
    static let PlaybackServicePolicyKey = ""
    static let VideoRef = ""
    static let AdConfigId = ""
}

class ViewController: UIViewController {
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var companionSlotContainerView: UIView!
    
    private lazy var fairplayAuthProxy: BCOVFPSBrightcoveAuthProxy? = {
        guard let _authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil) else {
            return nil
        }
        return _authProxy
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: Constants.AccountID, policyKey: Constants.PlaybackServicePolicyKey, baseURLStr: "https://edge.api.brightcove.com/playback/v1")
        return BCOVPlaybackService(requestFactory: factory)
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let manager = BCOVPlayerSDKManager.shared(), let fairplayAuthProxy = fairplayAuthProxy else {
            return nil
        }
        
        // Create a companion slot.
        let companionSlot = BCOVOUXCompanionSlot(view: companionSlotContainerView, width: 300, height: 250)
        
        // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
        let adComponentDisplayContainer = BCOVOUXAdComponentDisplayContainer(companionSlots: [companionSlot])
        
        let fairplaySessionProvider = manager.createFairPlaySessionProvider(with: fairplayAuthProxy, upstreamSessionProvider: nil)
        let ouxSessionProvider = manager.createOUXSessionProvider(withUpstreamSessionProvider: fairplaySessionProvider)
        
        guard let _playbackController = manager.createPlaybackController(with: ouxSessionProvider, viewStrategy: nil) else {
            return nil
        }
        
        // In order for the ad display container to receive ad information, we add it as a session consumer.
        _playbackController.add(adComponentDisplayContainer)
        
        _playbackController.delegate = self
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestContentFromPlaybackService()
    }
    
    private func requestContentFromPlaybackService() {
        let queryParameters = ["ad_config_id": Constants.AdConfigId]
        
        playbackService.findVideo(withReferenceID: Constants.VideoRef, parameters: queryParameters) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            guard let _video = video else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self?.playbackController?.setVideos([_video] as NSFastEnumeration)
        }
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

