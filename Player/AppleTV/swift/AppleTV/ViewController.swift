//
//  ViewController.swift
//  AppleTV
//
//  Copyright © 2017 Brightcove. All rights reserved.
//

import UIKit
import AVKit


let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM3n0ImwKortQqSZCgJMcyVbb8lJVwt0z16UD0a_h8MpEYcHyKbM8CGOPxBRp0nfSVdfokXBrUu3Sso7Nujv3dnLo0JxC_lNXCl88O7NJ0PR0z2AprnJ_Lwnq7nTcy1GBUrQPr5e"
let kViewControllerAccountID = "4800266849001"
let kViewControllerVideoID = "5255514387001"


class ViewController: UIViewController, BCOVPlaybackControllerDelegate
{
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    let avpvc = AVPlayerViewController()
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
        
        // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
        // since the AVPlayerViewController already makes one
        playbackController.options = [ kBCOVAVPlayerViewControllerCompatibilityKey: true ];
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.addChildViewController(self.avpvc);
        self.avpvc.view.frame = self.view.bounds;
        self.avpvc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.avpvc.view);
        self.avpvc.didMove(toParentViewController: self);
        
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
        
        self.avpvc.player = session.player;
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!)
    {
        
        NSLog("Event: %@", lifecycleEvent.eventType)
    }
}

