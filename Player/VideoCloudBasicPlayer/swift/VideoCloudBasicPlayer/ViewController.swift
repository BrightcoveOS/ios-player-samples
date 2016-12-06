//
//  ViewController.swift
//  VideoCloudBasicPlayer
//
//  Created by Mike Moscardini on 9/29/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

import UIKit


let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
let kViewControllerAccountID = "3636334163001"
let kViewControllerVideoID = "3666678807001"


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {

    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    let playbackController :BCOVPlaybackController
    @IBOutlet weak var videoContainerView: UIView!

    required init?(coder aDecoder: NSCoder)
    {
        let manager = BCOVPlayerSDKManager.sharedManager();
        playbackController = manager.createPlaybackControllerWithViewStrategy(nil)

        super.init(coder: aDecoder)

        playbackController.delegate = self
        playbackController.autoAdvance = true
        playbackController.autoPlay = true
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let controlView = BCOVPUIBasicControlView.basicControlViewWithVODLayout()
        let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: controlView)
        playerView.frame = self.videoContainerView.bounds
        playerView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.videoContainerView.addSubview(playerView)
        playerView.playbackController = playbackController

        requestContentFromCatalog()
    }

    func requestContentFromCatalog()
    {
        playbackService.findVideoWithVideoID(kViewControllerVideoID, parameters: nil) { (video: BCOVVideo!, jsonResponse: [NSObject : AnyObject]!, error: NSError!) -> Void in
            
            if let v = video
            {
                self.playbackController.setVideos([v])
            }
            else
            {
                NSLog("ViewController Debug - Error retrieving video playlist: %@", error)
            }
            
        }
    }

    func playbackController(controller: BCOVPlaybackController!, didAdvanceToPlaybackSession session: BCOVPlaybackSession!)
    {
        NSLog("ViewController Debug - Advanced to new session.")
    }

    // MARK: - UI Styling

    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
}

