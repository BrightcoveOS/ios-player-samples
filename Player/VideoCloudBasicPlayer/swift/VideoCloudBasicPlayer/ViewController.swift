//
//  ViewController.swift
//  VideoCloudBasicPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM3n0ImwKortQqSZCgJMcyVbb8lJVwt0z16UD0a_h8MpEYcHyKbM8CGOPxBRp0nfSVdfokXBrUu3Sso7Nujv3dnLo0JxC_lNXCl88O7NJ0PR0z2AprnJ_Lwnq7nTcy1GBUrQPr5e"
let kViewControllerAccountID = "4800266849001"
let kViewControllerVideoID = "5255514387001"

class ViewController: UIViewController, BCOVPlaybackControllerDelegate {
    
    let sharedSDKManager = BCOVPlayerSDKManager.shared()
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    let playbackController :BCOVPlaybackController
    @IBOutlet weak var videoContainerView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        playbackController = (sharedSDKManager?.createPlaybackController())!
        
        super.init(coder: aDecoder)
        
        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up our player view. Create with a standard VOD layout.
        guard let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return
        }
        
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
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("Advanced to new session")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        print("Progress: \(progress) seconds")
    }
}
