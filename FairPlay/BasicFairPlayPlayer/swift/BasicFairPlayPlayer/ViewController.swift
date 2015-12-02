//
//  ViewController.swift
//  BasicFairPlayPlayer
//
//  Created by Michael Moscardini on 12/2/15.
//  Copyright © 2015 Brightcove. All rights reserved.
//

import UIKit

//Customize these with your own settings.

let kViewControllerAccountId = ""
let kViewControllerPolicyKey = ""
let kViewControllerVideoId = ""

let kViewControllerFairPlayApplicationId = ""
let kViewControllerFairPlayPublisherId = ""


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {
    
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountId, policyKey: kViewControllerPolicyKey)
    let fairPlayAuthService = BCOVFPSBrightcoveAuthProxy(applicationId: kViewControllerFairPlayApplicationId, publisherId: kViewControllerFairPlayPublisherId)
    var playbackController :BCOVPlaybackController?
    @IBOutlet weak var videoContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Before we can initialize the player, we need to get the app cert. In a real app, you would
        // probably want to perform this process well ahead of time, as to not introduce a delay at the time of playback.
        fairPlayAuthService!.retrieveApplicationCertificate({ (applicationCertificate: NSData?, error: NSError?) -> Void in
            
            if let appCert = applicationCertificate
            {
                let sdkManager = BCOVPlayerSDKManager.sharedManager()
                let controller = sdkManager.createFairPlayPlaybackControllerWithApplicationCertificate(appCert, authorizationProxy:self.fairPlayAuthService!, viewStrategy: sdkManager.defaultControlsViewStrategy())
                controller.autoAdvance = false;
                controller.autoPlay = true;
                controller.delegate = self
                
                controller.view.frame = self.videoContainerView.bounds
                controller.view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
                self.videoContainerView.addSubview(controller.view)
                
                self.playbackController = controller;
                
                self.requestContentFromCatalog()
            }
            else
            {
                 NSLog("ViewController Debug - Error retrieving app certificate: %@", error!)
            }
            
        })
        
    }
    
    func requestContentFromCatalog() {
        playbackService.findVideoWithReferenceID(kViewControllerVideoId, parameters: nil) { (video: BCOVVideo!, jsonResponse: [NSObject : AnyObject]!, error: NSError!) -> Void in
            
            if let v = video
            {
                self.playbackController!.setVideos([v])
            }
            else
            {
                NSLog("ViewController Debug - Error retrieving video: %@", error)
            }
            
        }
    }
    
    func playbackController(controller: BCOVPlaybackController!, didAdvanceToPlaybackSession session: BCOVPlaybackSession!) {
        NSLog("ViewController Debug - Advanced to new session.")
    }
    
    // MARK: UI Styling
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
