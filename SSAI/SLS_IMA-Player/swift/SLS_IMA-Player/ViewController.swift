//
//  ViewController.swift
//  SLS_IMA-Player
//
//  Created by Carlos Ceja on 13/07/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import AppTrackingTransparency
import UIKit

import GoogleInteractiveMediaAds

import BrightcovePlayerSDK
import BrightcoveIMA
import BrightcoveSSAI


struct Constants {
    static let AccountID = "insertyouraccountidhere"
    static let PlaybackServicePolicyKey = "insertyourpolicykeyhere"
    static let VideoId = "insertyourvideoidhere"
    static let AdConfigId = "insertyouradconfigidhere"
}

struct IMAConfig {
    static let PublisherID = "insertyourpidhere"
    static let Language = "en"
    static let VMAPResponseAdTag = "insertyouradtaghere"
}


class ViewController: UIViewController {

    @IBOutlet weak var videoContainerView: UIView!
    
    private lazy var playerView: BCOVPUIPlayerView? = {
        
        let controlView = BCOVPUIBasicControlView.withLiveLayout()
        guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: nil, controlsView: controlView) else {
            return nil
        }
        
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
        
        guard let manager = BCOVPlayerSDKManager.shared(), let playerView = self.playerView else {
            return nil
        }
        
        let imaSettings = IMASettings()
        imaSettings.ppid = IMAConfig.PublisherID
        imaSettings.language = IMAConfig.Language
        
        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self
        renderSettings.linkOpenerDelegate = self
        
        // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()
        
        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us to modify the IMAAdsRequest object
        // before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]
        
        let basicSessionProvider = manager.createBasicSessionProvider(with: nil)
        let imaSessionProvider = manager.createIMASessionProvider(with: imaSettings, adsRenderingSettings: renderSettings, adsRequestPolicy: adsRequestPolicy, adContainer: playerView.contentOverlayView, viewController: self, companionSlots: nil, upstreamSessionProvider: basicSessionProvider, options: imaPlaybackSessionOptions)
        let ssaiSessionProvider = manager.createSSAISessionProvider(withUpstreamSessionProvider: imaSessionProvider)
        
        guard let _playbackController = manager.createPlaybackController(with: ssaiSessionProvider, viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoPlay = true
        _playbackController.isAutoAdvance = true
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: Constants.AccountID, policyKey: Constants.PlaybackServicePolicyKey)
        return BCOVPlaybackService(requestFactory: factory)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] (status: ATTrackingManager.AuthorizationStatus) in
                DispatchQueue.main.async {
                    self?.requestContentFromPlaybackService()
                }
            }
        } else {
            requestContentFromPlaybackService()
        }
    }
    
    private func requestContentFromPlaybackService() {
        let queryParameters = [kBCOVPlaybackServiceParamaterKeyAdConfigId: Constants.AdConfigId]
        
        self.playbackService.findVideo(withVideoID: Constants.VideoId, parameters: queryParameters) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            guard let video = video else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            var updatedVideo: BCOVVideo?
            
            video.update({ (mutableVideo: BCOVMutableVideo?) in
               
                guard let mutableVideo = mutableVideo else {
                    return
                }
                
                // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
                // the video's properties when using server side ad rules. This URL returns
                // a VMAP response that is handled by the Google IMA library.
                if var updatedProperties = mutableVideo.properties {
                    updatedProperties[kBCOVIMAAdTag] = IMAConfig.VMAPResponseAdTag
                    mutableVideo.properties = updatedProperties
                }
                
                updatedVideo = mutableVideo as? BCOVVideo
            })
            
            if let updatedVideo = updatedVideo {
                self?.playbackController?.setVideos([updatedVideo] as NSFastEnumeration)
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


// MARK: - IMALinkOpenerDelegate
extension ViewController: IMALinkOpenerDelegate {
    
    func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
        print("ViewController Debug - linkOpenerDidOpen")
    }
    
    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        print("ViewController Debug - linkOpenerDidClose")
    }
    
}
