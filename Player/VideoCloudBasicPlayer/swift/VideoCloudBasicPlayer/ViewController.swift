//
//  ViewController.swift
//  VideoCloudBasicPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import AVKit
import UIKit
import BrightcovePlayerSDK

let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerAccountID = "5434391461001"
let kViewControllerVideoID = "6140448705001"

class ViewController: UIViewController {
    
    let sharedSDKManager = BCOVPlayerSDKManager.shared()
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    let playbackController :BCOVPlaybackController
    var nowPlayingHandler: NowPlayingHandler?
    var playerView: BCOVPUIPlayerView?
    weak var currentPlayer: AVPlayer?
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var muteButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        playbackController = (sharedSDKManager?.createPlaybackController())!
        
        super.init(coder: aDecoder)
        
        playbackController.delegate = self
        playbackController.allowsBackgroundAudioPlayback = true
        playbackController.allowsExternalPlayback = true
        playbackController.isAutoPlay = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpAudioSession()
        
        // Set up our player view. Create with a standard VOD layout.
        let options = BCOVPUIPlayerViewOptions()
        options.showPictureInPictureButton = true
        
        guard let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: options, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return
        }
        
        self.playerView = playerView
        
        playerView.delegate = self
        
        // Install in the container view and match its size.
        self.videoContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
        ])
        
        // Associate the playerView with the playback controller.
        playerView.playbackController = playbackController
        
        nowPlayingHandler = NowPlayingHandler(withPlaybackController: playbackController)
        
        requestContentFromPlaybackService()
    }
    
    func requestContentFromPlaybackService() {
        playbackService?.findVideo(withVideoID: kViewControllerVideoID, parameters: nil) { (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            if let v = video {
                self.playbackController.setVideos([v] as NSArray)
            } else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func setUpAudioSession() {
        var categoryError :NSError?
        var success: Bool
        do {
            // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
            if let currentPlayer = currentPlayer {
                
                // If the player is muted, then allow mixing.
                // Ensure other apps can have their background audio
                // active when this app is in foreground
                if currentPlayer.isMuted {
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
                } else {
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: AVAudioSession.CategoryOptions(rawValue: 0))
                }
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: AVAudioSession.CategoryOptions(rawValue: 0))
            }
            
            success = true
        } catch let error as NSError {
            categoryError = error
            success = false
        }

        if !success {
            print("AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. \(categoryError!)")
        }
    }
    
    @IBAction func muteButtonPressed(_ button: UIButton) {
        guard let currentPlayer = currentPlayer else {
            return
        }
        
        if currentPlayer.isMuted {
            muteButton?.setTitle("Mute AVPlayer", for: .normal)
        } else {
            muteButton?.setTitle("Unmute AVPlayer", for: .normal)
        }
        
        currentPlayer.isMuted = !currentPlayer.isMuted
        
        setUpAudioSession()
    }

}

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("Advanced to new session")
        
        currentPlayer = session.player
        
        // Enable route detection for AirPlay
        // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
        playerView?.controlsView.routeDetector?.isRouteDetectionEnabled = true
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        print("Progress: \(progress) seconds")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd {
            // Disable route detection for AirPlay
            // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
            playerView?.controlsView.routeDetector?.isRouteDetectionEnabled = false
        }
    }
    
}

extension ViewController: BCOVPUIPlayerViewDelegate {
    
    func pictureInPictureControllerDidStartPicture(inPicture pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerDidStartPicture")
    }
    
    func pictureInPictureControllerDidStopPicture(inPicture pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerDidStopPicture")
    }
    
    func pictureInPictureControllerWillStartPicture(inPicture pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerWillStartPicture")
    }
    
    func pictureInPictureControllerWillStopPicture(inPicture pictureInPictureController: AVPictureInPictureController) {
        print("pictureInPictureControllerWillStopPicture")
    }
    
    func picture(_ pictureInPictureController: AVPictureInPictureController!, failedToStartPictureInPictureWithError error: Error!) {
        print("failedToStartPictureInPictureWithError \(error.localizedDescription)")
    }
    
}
