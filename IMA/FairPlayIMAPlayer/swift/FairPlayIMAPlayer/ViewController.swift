//
//  ViewController.swift
//  FairPlayIMAPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveIMA
import GoogleInteractiveMediaAds

struct PlaybackConfig {
    static let AccountID = ""
    static let PolicyKey = ""
    static let PlaylistID = ""
}

struct IMAConfig {
    static let PublisherID = "insertyourpidhere"
    static let Language = "en"
    static let VMAPResponseAdTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1"
}

class ViewController: UIViewController {

    @IBOutlet weak var videoContainerView: UIView!
    
    private var adIsPlaying = false
    private var notificationReceipt: AnyObject?
    
    private lazy var playerView: BCOVPUIPlayerView? = {
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
        
        return _playerView
    }()
    
    private var playbackController: BCOVPlaybackController?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(simulator)
        showSimulatorWarning()
        #endif
        
        setupPlaybackController()
        requestContent()
        resumeAdAfterForeground()
    }

    // MARK: - Misc
    
    private func setupPlaybackController() {
        
        let imaSettings = IMASettings()
        imaSettings.ppid = IMAConfig.PublisherID
        imaSettings.language = IMAConfig.Language
        
        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.webOpenerPresentingController = self
        renderSettings.webOpenerDelegate = self
        
        // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()
        
        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us to modify the IMAAdsRequest object
        // before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]
        
        guard let proxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil) else {
            return
        }
        
        let fps = BCOVPlayerSDKManager.shared()?.createFairPlaySessionProvider(with: proxy, upstreamSessionProvider: nil)
        
        // FairPlay is set as the upstream session provider when creating the IMA session provider.
        let imaSessionProvider = BCOVPlayerSDKManager.shared()?.createIMASessionProvider(with: imaSettings, adsRenderingSettings: renderSettings, adsRequestPolicy: adsRequestPolicy, adContainer: videoContainerView, companionSlots: nil, upstreamSessionProvider: fps, options: imaPlaybackSessionOptions)
        
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: imaSessionProvider, viewStrategy: nil) else {
            return
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        // Creating a playback controller based on the above code will create
        // VMAP / Server Side Ad Rules. These settings are explained in BCOVIMAAdsRequestPolicy.h.
        // If you want to change these settings, you can initialize the plugin like so:
        //
        // let adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vmapAdTagUrl: IMAConfig.VMAPResponseAdTag)
        //
        // or for VAST:
        //
        // let policy = BCOVCuePointProgressPolicy.init(processingCuePoints: .processFinalCuePoint, resumingPlaybackFrom: .fromContentPlayhead, ignoringPreviouslyProcessedCuePoints: false)
        //
        // let adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vastAdTagsInCuePointsAndAdsCuePointProgressPolicy: policy)
        //
        // _playbackController = BCOVPlayerSDKManager.shared()?.createIMAPlaybackController(with: imaSettings, adsRenderingSettings: renderSettings, adsRequestPolicy: adsRequestPolicy, adContainer: playerView?.contentOverlayView, companionSlots: nil, viewStrategy: nil, options: imaPlaybackSessionOptions)
        //
        
        playbackController = _playbackController
    }
    
    private func requestContent() {
        
        print("Request video content")
        
        let queryParams = ["limit": 100, "offset": 0]
        // Retrieve a playlist through the BCOVPlaybackService
        let playbackServiceRequestFactory = BCOVPlaybackServiceRequestFactory(accountId: PlaybackConfig.AccountID, policyKey: PlaybackConfig.PolicyKey)
        
        let playbackService = BCOVPlaybackService(requestFactory: playbackServiceRequestFactory)
        playbackService?.findPlaylist(withReferenceID: PlaybackConfig.PlaylistID, parameters: queryParams, completion: { [weak self] (playlist: BCOVPlaylist?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            
            let updatedPlaylist = playlist?.update({ (mutablePlaylist: BCOVMutablePlaylist?) in
                
                guard let mutablePlaylist = mutablePlaylist else {
                    return
                }
                
                var updatedVideos:[BCOVVideo] = []
                
                for video in mutablePlaylist.videos {
                    if let _video = video as? BCOVVideo {
                        updatedVideos.append(_video.updateVideo(withVMAPTag: IMAConfig.VMAPResponseAdTag))
                    }
                }
                
                mutablePlaylist.videos = updatedVideos
                
            })
            
            
            if let _updatedPlaylist = updatedPlaylist {
                self?.playbackController?.setVideos(_updatedPlaylist.videos as NSFastEnumeration)
            }
            
            
        })

    }
    
    private func resumeAdAfterForeground() {
        
        // When the app goes to the background, the Google IMA library will pause
        // the ad. This code demonstrates how you would resume the ad when entering
        // the foreground.
        
        notificationReceipt = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil, using: { [weak self] (notification: Notification) in
            
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.adIsPlaying {
                strongSelf.playbackController?.resumeAd()
            }
        })
    }
    
    private func showSimulatorWarning() {
        
        let alert = UIAlertController(title: "FairPlay Warning", message: "FairPlay only work son actual iOS devices, not in a simulator.\n\nYou will not be able to view any FairPlay content.", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
        // The events are defined BCOVIMAComponent.h.
        
        let type = lifecycleEvent.eventType
        
        if type == kBCOVIMALifecycleEventAdsLoaderLoaded {
            print("ViewController Debug - Ads loaded.")
            
            // When ads load successfully, the kBCOVIMALifecycleEventAdsLoaderLoaded lifecycle event
            // returns an NSDictionary containing a reference to the IMAAdsManager.
            guard let adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager] as? IMAAdsManager else {
                return
            }
            
            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0
            let volumeString = String(format: "%0.1", adsManager.volume)
            print("ViewController Debug - IMAAdsManager.volume set to \(volumeString)")
            
        } else if type == kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent {
            
            guard let adEvent = lifecycleEvent.properties["adEvent"] as? IMAAdEvent else {
                return
            }
            
            switch adEvent.type {
            case .STARTED:
                print("ViewController Debug - Ad Started.")
                adIsPlaying = true
            case .COMPLETE:
                print("ViewController Debug - Ad Completed.")
                adIsPlaying = false
            case .ALL_ADS_COMPLETED:
                print("ViewController Debug - All ads completed.")
            default:
                break
            }
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
        // Hide all controls for ads (so they're not visible when full-screen)
        playerView?.controlsContainerView.alpha = 0.0
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
        // Show all controls when ads are finished.
        playerView?.controlsContainerView.alpha = 1.0
    }
    
}

// MARK: - BCOVIMAPlaybackSessionDelegate

extension ViewController: BCOVIMAPlaybackSessionDelegate {
    
    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!, forPosition position: TimeInterval) {
        // for demo purposes, increase the VAST ad load timeout.
        adsRequest.vastLoadTimeout = 3000.0
        let timeoutStringFormat = String(format: "%.1", adsRequest.vastLoadTimeout)
        print("ViewController Debug - IMAAdsRequest.vastLoadTimeout set to \(timeoutStringFormat) milliseconds.")
    }
    
}

// MARK: - IMAWebOpenerDelegate

extension ViewController: IMAWebOpenerDelegate {
    
    func webOpenerDidClose(inAppBrowser webOpener: NSObject!) {
        // Called when the in-app browser has closed.
        playbackController?.resumeAd()
    }
    
}
