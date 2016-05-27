//
//  ViewController.swift
//  BasicFairPlayPlayer
//
//  Created by Michael Moscardini on 12/2/15.
//  Copyright © 2015 Brightcove. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveFairPlay

//Customize these with your own settings.

let kViewControllerAccountId = ""
let kViewControllerPolicyKey = ""
let kViewControllerVideoReferenceId = ""

let kViewControllerFairPlayApplicationId = ""
let kViewControllerFairPlayPublisherId = ""


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {
    
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountId, policyKey: kViewControllerPolicyKey)
    let fairPlayAuthService = BCOVFPSBrightcoveAuthProxy(publisherId: kViewControllerFairPlayPublisherId, applicationId: kViewControllerFairPlayApplicationId)
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
                
                // Set up source selection to prefer HLS files using HTTPS
                let options = BCOVBasicSessionProviderOptions()
                options.sourceSelectionPolicy = BCOVBasicSourceSelectionPolicy.sourceSelectionHLSWithScheme(kBCOVSourceURLSchemeHTTPS)

                // Create chain of session providers
                let psp = sdkManager.createBasicSessionProviderWithOptions(options)
                let fps = sdkManager.createFairPlaySessionProviderWithApplicationCertificate(appCert, authorizationProxy:self.fairPlayAuthService!, upstreamSessionProvider:psp)

                // Create playback controller
                let controller = sdkManager.createPlaybackControllerWithSessionProvider(fps, viewStrategy:sdkManager.defaultControlsViewStrategy())

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
        playbackService.findVideoWithReferenceID(kViewControllerVideoReferenceId, parameters: nil) { (video: BCOVVideo!, jsonResponse: [NSObject : AnyObject]!, error: NSError!) -> Void in
            
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
    
    func playbackController(controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession, didReceiveLifecycleEvent lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        // Report any errors that may have occurred with playback.
        if (kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType)
        {
            let error = lifecycleEvent.properties["error"] as! NSError;
            NSLog("Playback error: %@", error);
        }
    }
    
    // MARK: UI Styling
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
