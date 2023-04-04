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
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let AccountID = "5434391461001"
    static let VideoID = "6140448705001"
}

struct PulseConfig
{
    // Replace with your own Pulse Host info:
    static let PulseHost = "https://bc-test.videoplaza.tv"
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

        let persistentId = UIDevice.current.identifierForVendor?.uuidString

        let pulseProperties = [
            kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
            kBCOVPulseOptionPulsePersistentIdKey: persistentId!
            ] as [String : Any]

        /**
         *  Initialize the Brightcove Pulse Plugin.
         *  Host:
         *      The host is derived from the "sub-domain” found in the Pulse UI and is formulated
         *      like this: `https://[sub-domain].videoplaza.tv`
         *  Device Container (kBCOVPulseOptionPulseDeviceContainerKey):
         *      The device container in Pulse is used for targeting and reporting purposes.
         *      This device container attribute is only used if you want to override the Pulse
         *      device detection algorithm on the Pulse ad server. This should only be set if normal
         *      device detection does not work and only after consulting our personnel.
         *      An incorrect device container value can result in no ads being served
         *      or incorrect ad delivery and reports.
         *  Persistent Id (kBCOVPulseOptionPulsePersistentIdKey):
         *      The persistent identifier is used to identify the end user and is the
         *      basis for frequency capping, uniqueness, DMP targeting information and
         *      more. Use Apple's advertising identifier (IDFA), or your own unique
         *      user identifier here.
         *
         *  Refer to:
         *  https://docs.invidi.com/r/INVIDI-Pulse-Documentation/Pulse-SDKs-parameter-reference
         */

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
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:PlaybackConfig.VideoID]
        playbackService.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            if let video = video
            {
                self?.video = video
                self?.playbackController?.setVideos([self?.video] as NSFastEnumeration)

                if self?.videoItem?.extendSession != nil {

                    if let strongSelf = self {
                        // Delay execution.
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {

                            /**
                             * You cannot request insertion points that have been requested already. For example,
                             * if you have already requested post-roll ads, then you cannot request them again.
                             * You can request additional mid-rolls, but only for cue points that have not been
                             * requested yet. For example, if you have already requested mid-rolls to show after 10 seconds
                             * and 30 seconds of video content playback, you can only request more mid-rolls for times that
                             * differ from 10 and 30 seconds.
                             */

                            print("Request a session extension for midroll ads at 30th second.")

                            let extendContentMetadata = OOContentMetadata()
                            extendContentMetadata.tags = ["standard-midrolls"]

                            let extendRequestSettings = OORequestSettings()
                            extendRequestSettings.linearPlaybackPositions = [30]
                            extendRequestSettings.insertionPointFilter = OOInsertionPointType.playbackPosition

                            (strongSelf.pulseSessionProvider as? BCOVPulseSessionProvider)?.requestSessionExtension(with: extendContentMetadata, requestSettings: extendRequestSettings, success: {

                                print("Session was successfully extended. There are now midroll ads at 30th second.")

                            })
                        }

                    }
                }
            }
            else
            {
                print("PlayerViewController Debug - Error retrieving video: \(error!.localizedDescription)")
            }
        })
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
    func createSession(for video: BCOVVideo!, withPulseHost pulseHost: String!, contentMetadata: OOContentMetadata!, requestSettings: OORequestSettings!) -> OOPulseSession!
    {
        if pulseHost == nil
        {
            return nil
        }

        // Override the content metadata.
        contentMetadata.category = self.videoItem?.category
        contentMetadata.tags = self.videoItem?.tags

        // Override the request settings.
        requestSettings.linearPlaybackPositions = self.videoItem?.midrollPositions

        return OOPulse.session(with: contentMetadata, requestSettings: requestSettings)
    }
}
