//
//  ViewController.swift
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 3/13/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import Foundation

import BrightcovePlayerSDK
import BrightcovePulse


struct PlaybackConfig
{
    static let PolicyKey = "insertyourservicepolicykeyhere"
    static let AccountID = "insertyouraccountidhere"
    static let VideoID = "insertyourvideoidhere"
}

struct PulseConfig
{
    static let PulseHost = "insertyourpulsehosthere"
}


class ViewController: UIViewController
{
    public var videoItem: BCOVPulseVideoItem?
    
    private var video: BCOVVideo?
    
    @IBOutlet private weak var videoContainerView: UIView!
    
    private lazy var playbackService: BCOVPlaybackService =
    {
        return BCOVPlaybackService(accountId: PlaybackConfig.AccountID, policyKey: PlaybackConfig.PolicyKey)
    }()
    
    private lazy var playerView: BCOVTVPlayerView? =
    {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        
        // Create PlayerUI views with normal VOD controls.
        guard let _playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }
        
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to parent view
        self.videoContainerView.addSubview(_playerView)
        
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
            ])
        
        return _playerView
    }()
    
    private lazy var pulseSessionProvider: BCOVPlaybackSessionProvider? =
    {
        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
        let contentMetadata = OOContentMetadata()
        
        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
        let requestSettings = OORequestSettings()
        
        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Enums/OOSeekMode.html
        requestSettings.seekMode = OOSeekMode.PLAY_ALL_ADS
        
        let pulseProperties = [
            kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
            kBCOVPulseOptionPulsePersistentIdKey: UUID.init().uuidString
            ] as [String : Any]

        guard let _pulseSessionProvider = BCOVPlayerSDKManager.shared()?.createPulseSessionProvider(withPulseHost: PulseConfig.PulseHost, contentMetadata: contentMetadata, requestSettings: requestSettings, adContainer: self.playerView?.contentOverlayView, companionSlots: [], upstreamSessionProvider: nil, options: pulseProperties) else {
            return nil
        }
        
        return _pulseSessionProvider
    }()
    
    private lazy var playbackController: BCOVPlaybackController? =
    {
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: self.pulseSessionProvider, viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.isAutoPlay = true
        _playbackController.isAutoAdvance = true
        _playbackController.delegate = self
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let _ = playerView
        let _ = playbackController
        
        requestVideo()
    }
    
    // MARK: Private Methods
    
    func requestVideo()
    {
        playbackService.findVideo(withVideoID: PlaybackConfig.VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            if let video = video
            {
                self?.video = video
                self?.playbackController?.setVideos([self?.video] as NSFastEnumeration)
            }
            else
            {
                print("PlayerViewController Debug - Error retrieving video: \(error!.localizedDescription)")
            }
        }
    }

    // MARK: UI
    // Preferred focus for tvOS 10+
    override var preferredFocusEnvironments: [UIFocusEnvironment]
    {
        return [playerView?.controlsView ?? self]
    }

}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate
{
    func playbackController(_ controller: BCOVPlaybackController?, didAdvanceTo session: BCOVPlaybackSession?)
    {
        print("ViewController Debug - Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController?, playbackSession session: BCOVPlaybackSession?, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent?)
    {
        if let eventType = lifecycleEvent?.eventType
        {
            print("Event: \(eventType)")
        }
    }
}


// MARK: - BCOVPulsePlaybackSessionDelegate

extension ViewController: BCOVPulsePlaybackSessionDelegate
{
    func createSession(for video: BCOVVideo!, withPulseHost pulseHost: String!, contentMetdata contentMetadata: OOContentMetadata!, requestSettings: OORequestSettings!) -> OOPulseSession!
    {
        if pulseHost == nil
        {
            return nil
        }

        // Override the content metadata.
        contentMetadata.category = self.videoItem?.category
        contentMetadata.tags = self.videoItem?.tags
        contentMetadata.flags = self.videoItem?.flags

        // Override the request settings.
        requestSettings.linearPlaybackPositions = self.videoItem?.midrollPositions

        return OOPulse.session(with: contentMetadata, requestSettings: requestSettings)
    }
}
