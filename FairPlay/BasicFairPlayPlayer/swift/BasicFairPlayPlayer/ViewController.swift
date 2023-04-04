//
//  ViewController.swift
//  BasicFairPlayPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit

// Add your Brightcove account and video information here.
// The video should be encrypted with FairPlay
let kViewControllerVideoCloudAccountId = "5434391461001"
let kViewControllerVideoCloudPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerVideoId = "6140448705001"

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
        
        if let _view = playbackController?.view {
            _view.translatesAutoresizingMaskIntoConstraints = false
            videoContainerView.addSubview(_view)
            NSLayoutConstraint.activate([
                _view.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
                _view.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
                _view.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
                _view.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
            ])
        }
        
        self.playbackController = playbackController
        
        self.requestContentFromPlaybackService()
        self.createPlayerView()
    }
    
    func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:kViewControllerVideoId]
        playbackService?.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            if video == nil
            {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self?.playbackController!.setVideos([ video! ] as NSArray)
        })
    }
    
    // Create the player view
    func createPlayerView() {
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        guard let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: controlView) else {
            return
        }
        videoContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
            ])
        
        playerView.playbackController = self.playbackController
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
