//
//  ViewController.swift
//  BasicFairPlayPlayer
//
//  Copyright © 2017 Brightcove, Inc. All rights reserved.
//

import UIKit

// Add your Brightcove account and video information here.
// The video should be encrypted with FairPlay
let kViewControllerVideoCloudAccountId = ""
let kViewControllerVideoCloudPolicyKey = ""
let kViewControllerVideoReferenceId = ""

// If you are using Dynamic Delivery you don't need to set these
let kViewControllerFairPlayApplicationId = ""
let kViewControllerFairPlayPublisherId = ""


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {
    let playbackService = BCOVPlaybackService(accountId: kViewControllerVideoCloudAccountId, policyKey: kViewControllerVideoCloudPolicyKey)
    var fairPlayAuthProxy: BCOVFPSBrightcoveAuthProxy?
    var playbackController :BCOVPlaybackController?
    @IBOutlet weak var videoContainerView: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if kViewControllerVideoCloudAccountId == ""
        {
            print("\n***** WARNING *****")
            print("Remember to add your account credentials at the top of ViewController.swift")
            print("***** WARNING *****")
            return
        }
        
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        
        // This shows the two ways of using the Brightcove FairPlay session provider:
        // Set to true for Dynamic Delivery; false for a legacy Video Cloud account
        let using_dynamic_delivery = true
        
        if (( using_dynamic_delivery ))
        {
            // If you're using Dynamic Delivery, you don't need to load
            // an application certificate. The FairPlay session will load an
            // application certificate for you if needed.
            // You can just load and play your FairPlay videos.
            
            // If you are using Dynamic Delivery, you can pass nil for the publisherId and applicationId,
            self.fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
                                                                applicationId: nil)
            
            // Create chain of session providers
            let psp = sdkManager?.createBasicSessionProvider(with:nil)
            let fps = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate:nil,
                                                                authorizationProxy:self.fairPlayAuthProxy!,
                                                                upstreamSessionProvider:psp)
            
            // Create the playback controller
            let playbackController = sdkManager?.createPlaybackController(with:fps, viewStrategy:nil)
            
            playbackController?.isAutoAdvance = false
            playbackController?.isAutoPlay = true
            playbackController?.delegate = self
            
            if playbackController?.view != nil {
                playbackController?.view.frame = self.videoContainerView.bounds
                playbackController?.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                self.videoContainerView.addSubview((playbackController!.view)!)
            }
            
            self.playbackController = playbackController
            
            self.requestContentFromPlaybackService()
            self.createPlayerView()
        }
        else
        {
            // Legacy Video Cloud account
            
            // You can create your FairPlay session provider first, and give it an
            // application certificate later, but in this application we want to play
            // right away, so it's easier to load our player as soon as we know
            // that we have an application certificate.
            
            // Retrieve application certificate using the FairPlay auth proxy
            self.fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: kViewControllerFairPlayPublisherId,
                                                                applicationId: kViewControllerFairPlayApplicationId)
            
            self.fairPlayAuthProxy?.retrieveApplicationCertificate() { (applicationCertificate: Data?, error: Error?) -> Void in
                guard let appCert = applicationCertificate else
                {
                    print("ViewController Debug - Error retrieving app certificate: %@", error!)
                    return
                }
                
                // Create chain of session providers
                let psp = sdkManager?.createBasicSessionProvider(with:nil)
                let fps = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate:appCert,
                                                                    authorizationProxy:self.fairPlayAuthProxy!,
                                                                    upstreamSessionProvider:psp)
                
                // Create the playback controller
                let playbackController = sdkManager?.createPlaybackController(with:fps, viewStrategy:nil)
                
                playbackController?.isAutoAdvance = false
                playbackController?.isAutoPlay = true
                playbackController?.delegate = self
                
                if playbackController?.view != nil {
                    playbackController?.view.frame = self.videoContainerView.bounds
                    playbackController?.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                    self.videoContainerView.addSubview((playbackController!.view)!)
                }
                
                self.playbackController = playbackController
                
                self.requestContentFromPlaybackService()
                self.createPlayerView()
            }
        }
    }
    
    func requestContentFromPlaybackService() {
        playbackService?.findVideo(withReferenceID:kViewControllerVideoReferenceId, parameters: nil) { (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            if video == nil
            {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self.playbackController!.setVideos([ video! ] as NSArray)
        }
    }
    
    // Create the player view
    func createPlayerView() {
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: controlView)
        playerView?.frame = self.videoContainerView.bounds
        playerView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.videoContainerView.addSubview(playerView!)
        playerView?.playbackController = self.playbackController
    }
    
    func playbackController(_: BCOVPlaybackController!, didAdvanceTo: BCOVPlaybackSession!) {
        print("ViewController Debug: Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        // Report any errors that may have occurred with playback.
        if (kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType)
        {
            let error = lifecycleEvent.properties["error"] as! NSError
            print("Playback error: \(error.localizedDescription)")
        }
    }
}
