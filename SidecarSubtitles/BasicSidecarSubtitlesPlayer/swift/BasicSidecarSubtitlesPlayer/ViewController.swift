//
//  ViewController.swift
//  BasicSidecarSubtitlesPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve a video from Video Cloud
 * and add a sidecar VTT captions file to it for playback.
 *
 * The interesting methods in the code are `-requestContentFromPlaybackService` and
 * `-setupSubtitles`.
 *
 * `-requestContentFromPlaybackService` retrieves a video from Video Cloud
 * normally, but then it creates an array of text tracks, and adds them to the
 * BCOVVideo object. BCOVVideo is an immutable object, but you can create a new
 * modified copy of it by calling `BCOVVideo update:`.
 *
 * `-setupSubtitles` creates the array of subtitle dictionaries.
 * When creating these dictionaries, be sure to make note of which fields
 * are required are optional as specified in BCOVSSComponent.h.
 *
 * Note that in this sample the subtitle track does not match the audio of the
 * video; it's only used as an example.
 *
 */

import UIKit
import BrightcovePlayerSDK

struct ConfigConstants {
    static let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    static let AccountID = "3636334163001"
    static let VideoID = "3666678807001"
}

class ViewController: UIViewController {
    
    @IBOutlet weak var videoContainerView: UIView!
    
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
        
        // Receive delegate method callbacks
        _playerView.delegate = self
        
        return _playerView
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createSidecarSubtitlesPlaybackController(viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        return BCOVPlaybackService(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PlaybackServicePolicyKey)
    }()
    
    private lazy var textTracks: [[String:Any]] = {
        
        // Create the array of subtitle dictionaries
        return [
                [
                // required tracks descriptor: kBCOVSSTextTracksKindSubtitles or kBCOVSSTextTracksKindCaptions
                kBCOVSSTextTracksKeyKind: kBCOVSSTextTracksKindSubtitles,
                
                // required language code
                kBCOVSSTextTracksKeySourceLanguage: "en",
                
                // required display name
                kBCOVSSTextTracksKeyLabel: "English",
                
                // required: source URL of WebVTT file or playlist as NSString
                kBCOVSSTextTracksKeySource: "http://players.brightcove.net/3636334163001/ios_native_player_sdk/vtt/sample.vtt",
                
                // optional MIME type
                kBCOVSSTextTracksKeyMIMEType: "text/vtt",
                
                // optional "default" indicator
                kBCOVSSTextTracksKeyDefault: true,
                
                // duration is required for WebVTT URLs (ending in ".vtt");
                // optional for WebVTT playlists (ending in ".m3u8")
                kBCOVSSTextTracksKeyDuration: NSNumber(value: 959), // seconds as NSNumber
                
                // The source type is only needed if your source URL
                // does not end in ".vtt" or ".m3u8" and thus its type is ambiguous.
                // Our URL ends in ".vtt" so we don't need to set this, but it won't hurt.
                kBCOVSSTextTracksKeySourceType: kBCOVSSTextTracksKeySourceTypeWebVTTURL
            ]
        ]
        
    }()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestContentFromPlaybackService()
    }

    // MARK: - Misc
    
    private func requestContentFromPlaybackService() {
        
        playbackService.findVideo(withVideoID: ConfigConstants.VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            if let video = video {
                
                let updatedVideo = video.update({ (mutableVideo: BCOVMutableVideo?) in
                    
                    // Get the existing text tracks, if any
                    guard let strongSelf = self, let properties = mutableVideo?.properties, let currentTextTracks = mutableVideo?.properties[kBCOVSSVideoPropertiesKeyTextTracks] as? [[String:Any]] else {
                        return
                    }

                    // Combine the two arrays together.
                    // We don't want to lose the original tracks that might already be in there.
                    let combinedTextTracks: [[String:Any]] = currentTextTracks + strongSelf.textTracks

                    // Store text tracks in the text tracks property
                    var updatedDictionary = properties
                    updatedDictionary[kBCOVSSVideoPropertiesKeyTextTracks] = combinedTextTracks
                    mutableVideo?.properties = updatedDictionary
                    
                })
                
                self?.playbackController?.setVideos([updatedVideo] as NSFastEnumeration)
            }
            
            if let error = error {
                print("Error retrieving video: \(error.localizedDescription)")
            }
            
        }
        
    }

}

// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
 
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if let lifecycleEvent = lifecycleEvent {
            print("Received lifecycle event: \(lifecycleEvent)")
        }
    }
    
}
