//
//  ViewController.swift
//  BasicSSAIPlayer
//
//  Created by Jeremy Blaker on 3/15/19.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
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
    static let VMAPURL = "https://sdks.support.brightcove.com/assets/ads/ssai/sample-vmap.xml"
}

class ViewController: UIViewController {
    
    // When this value is set to YES the playback service
    // will be bypassed and a hard-coded VMAP URL will be used
    // to create a BCOVVideo instead
    let useVMAPURL = false

    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var companionSlotContainerView: UIView!
    
    private lazy var fairplayAuthProxy: BCOVFPSBrightcoveAuthProxy? = {
        guard let _authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil) else {
            return nil
        }
        return _authProxy
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: Constants.AccountID, policyKey: Constants.PlaybackServicePolicyKey)
        return BCOVPlaybackService(requestFactory: factory)
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let manager = BCOVPlayerSDKManager.shared(), let fairplayAuthProxy = fairplayAuthProxy else {
            return nil
        }
        
        // Create a companion slot.
        let companionSlot = BCOVSSAICompanionSlot(view: companionSlotContainerView, width: 300, height: 250)
        
        // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
        let adComponentDisplayContainer = BCOVSSAIAdComponentDisplayContainer(companionSlots: [companionSlot])
        
        let fairplaySessionProvider = manager.createFairPlaySessionProvider(with: fairplayAuthProxy, upstreamSessionProvider: nil)

        // To take the advantage of using IAB Open Measurement, the SSAI Plugin for iOS provides a new signature:
        // BCOVPlayerSDKManager.sharedManager.createSSAISessionProvider(withUpstreamSessionProvider:, omidPartner:).
        //
        // let ssaiSessionProvider = manager.createSSAISessionProvider(withUpstreamSessionProvider: fairplaySessionProvider, omidPartner: "yourOmidPartner")
        //
        // The `omidPartner` string identifies the integration. The value can not be empty or nil, if partner is not available, use "unknown".
        // The IAB Tech Lab will assign a unique partner name to you at the time of integration, so this is the value you should use here.

        let ssaiSessionProvider = manager.createSSAISessionProvider(withUpstreamSessionProvider: fairplaySessionProvider)
        
        guard let _playbackController = manager.createPlaybackController(with: ssaiSessionProvider, viewStrategy: nil) else {
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
        
        if useVMAPURL {
            let video = BCOVVideo(url: URL(string: Constants.VMAPURL)!)
            playbackController?.setVideos([video] as NSFastEnumeration)
        }
        else
        {
            requestContentFromPlaybackService()
        }
    }
    
    private func requestContentFromPlaybackService() {
        let queryParameters = [kBCOVPlaybackServiceParamaterKeyAdConfigId: Constants.AdConfigId]
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:Constants.VideoId]
        playbackService.findVideo(withConfiguration: configuration, queryParameters: queryParameters, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            guard let _video = video else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self?.playbackController?.setVideos([_video] as NSFastEnumeration)
        })
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

