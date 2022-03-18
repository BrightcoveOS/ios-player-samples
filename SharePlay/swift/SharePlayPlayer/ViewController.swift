//
//  ViewController.swift
//  SharePlayPlayer
//
//  Created by Jeremy Blaker on 3/17/22.
//

import UIKit
import BrightcovePlayerSDK

let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerAccountID = "5434391461001"
let kViewControllerVideoID = "6140448705001"

class ViewController: UIViewController {
    
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var playWithSharePlayButton: UIButton!
    @IBOutlet weak var playLocallyButton: UIButton!
    @IBOutlet weak var endSharePlayButton: UIButton!
    @IBOutlet weak var groupSessionLabel: UILabel!
    
    var playerView: BCOVPUIPlayerView?
    var playbackController: BCOVPlaybackController?
    var watchTogether: WatchTogetherWrapper?
    var playWithSharePlay = false
    var sourceSelectionPolicy: BCOVBasicSessionProviderSourceSelectionPolicy?
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endSharePlayButton.isEnabled = false
        
        playbackControllerSetup()
        playerViewSetup()
        
        watchTogether = WatchTogetherWrapper()
        watchTogether?.delegate = self
        watchTogether?.playbackController = playbackController
        playbackController?.add(watchTogether)
        
        sourceSelectionPolicy = BCOVBasicSourceSelectionPolicy.sourceSelectionHLS(withScheme: "https")
    }
    
    private func playbackControllerSetup() {
        playbackController = BCOVPlayerSDKManager.shared().createPlaybackController()
    }
    
    private func playerViewSetup() {
        // Set up our player view. Create with a standard VOD layout.
        let options = BCOVPUIPlayerViewOptions()
        options.showPictureInPictureButton = true
        
        guard let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: options, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return
        }
        
        self.playerView = playerView

        // Install in the container view and match its size.
        self.videoContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
        ])
    }
    
    private func requestContentFromPlaybackService() {
        playbackService?.findVideo(withVideoID: kViewControllerVideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            if let video = video {
                guard let _self = self else {
                    return
                }
                
                if _self.playWithSharePlay {
                    print("ViewController Debug - Playing video with SharePlay")
                    if let source = _self.sourceSelectionPolicy?(video) {
                        _self.watchTogether?.activateNewActivity(withVideo: video, withSource: source)
                    }
                } else {
                    print("ViewController Debug - Playing video locally")
                    _self.playbackController?.setVideos([video] as NSArray)
                }
            } else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    private func updateSessionLabel(withStatus status: String) {
        groupSessionLabel.text = "Group Session: \(status)"
    }
    
    // MARK: - IBActions
    @IBAction func playWithSharePlayButtonPressed(_ button: UIButton) {
        playWithSharePlay = true
        requestContentFromPlaybackService()
    }
    
    @IBAction func playLocallyButtonPressed(_ button: UIButton) {
        // End the existing SharePlay activity if needed
        watchTogether?.endSharePlay()
        
        playWithSharePlay = false
        requestContentFromPlaybackService()
    }
    
    @IBAction func endSharePlayButtonPressed(_ button: UIButton) {
        watchTogether?.endSharePlay()
    }

}

extension ViewController: WatchTogetherWrapperDelegate {
    func groupSessionWasJoined() {
        print("ViewController Debug - Activity was Joined")
        DispatchQueue.main.async {
            self.updateSessionLabel(withStatus: "Joined")
            self.endSharePlayButton.isEnabled = true
        }
    }
    
    func groupSessionWasInvalidated() {
        print("ViewController Debug - Activity was Invalidated")
        DispatchQueue.main.async {
            self.updateSessionLabel(withStatus: "Inactive")
            self.endSharePlayButton.isEnabled = false
        }
    }
    
    func activityWasDisabled() {
        print("ViewController Debug - Activity was Disabled or No Activity Active")
        DispatchQueue.main.async {
            self.updateSessionLabel(withStatus: "Inactive")
            self.endSharePlayButton.isEnabled = false
        }
    }
    
    func activityWasActivated() {
        print("ViewController Debug - Activity did Activate")
    }
    
    func activityFailedActivation() {
        print("ViewController Debug - Activity Failed to Activate")
    }
}

