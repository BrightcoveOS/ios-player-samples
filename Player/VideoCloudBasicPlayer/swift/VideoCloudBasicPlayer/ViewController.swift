//
//  ViewController.swift
//  VideoCloudBasicPlayer
//
//  Copyright © 2017 Brightcove, Inc. All rights reserved.
//

import UIKit


let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM3n0ImwKortQqSZCgJMcyVbb8lJVwt0z16UD0a_h8MpEYcHyKbM8CGOPxBRp0nfSVdfokXBrUu3Sso7Nujv3dnLo0JxC_lNXCl88O7NJ0PR0z2AprnJ_Lwnq7nTcy1GBUrQPr5e"
let kViewControllerAccountID = "4800266849001"
let kViewControllerVideoID = "5255514387001"


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {

    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    let playbackController :BCOVPlaybackController
    @IBOutlet weak var videoContainerView: UIView!

    required init?(coder aDecoder: NSCoder)
    {
        let manager = BCOVPlayerSDKManager.shared();
        playbackController = (manager?.createPlaybackController(viewStrategy: nil))!

        super.init(coder: aDecoder)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let controlView = BCOVPUIBasicControlView.withVODLayout()
        let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: controlView)
        playerView?.frame = self.videoContainerView.bounds
        playerView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.videoContainerView.addSubview(playerView!)
        playerView?.playbackController = playbackController

        requestContentFromPlaybackService()
    }

    func requestContentFromPlaybackService()
    {
        playbackService?.findVideo(withVideoID: kViewControllerVideoID, parameters: nil) { (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            if let v = video
            {
                self.playbackController.setVideos([v] as NSArray)
            }
            else
            {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!)
    {
        NSLog("ViewController Debug - Advanced to new session.")
    }

    // MARK: - UI Styling

    override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return .lightContent
    }
}

