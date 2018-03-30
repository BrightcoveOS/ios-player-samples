//
//  ViewController.swift
//  AppleTV
//
//  Copyright © 2018 Brightcove. All rights reserved.
//

// This sample app shows how to set up and use the TV Player UI on tvOS.
// It also shows how to subclass BCOVTVTabBarItemView to create your
// own top tab bar item view with your own controls.

import BrightcovePlayerSDK

let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM3n0ImwKortQqSZCgJMcyVbb8lJVwt0z16UD0a_h8MpEYcHyKbM8CGOPxBRp0nfSVdfokXBrUu3Sso7Nujv3dnLo0JxC_lNXCl88O7NJ0PR0z2AprnJ_Lwnq7nTcy1GBUrQPr5e"
let kViewControllerAccountID = "4800266849001"
let kViewControllerVideoID = "5754208017001"

class ViewController: UIViewController, BCOVPlaybackControllerDelegate
{
    @IBOutlet weak var videoContainerView: UIView!
    
    var playerView: BCOVTVPlayerView?
    
    let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
    
    let playbackController: BCOVPlaybackController = BCOVPlayerSDKManager.shared().createPlaybackController()
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        createTVPlayerView()
        
        createSampleTabBarItemView()
        
        // Create and configure the playback controller
        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        
        // Link the playback controller to the Player View
        playerView?.playbackController = playbackController
        
        requestContentFromPlaybackService()
    }
    
    func createTVPlayerView() {
        
        // Make sure storyboard bindings are set up
        self.loadViewIfNeeded()
        if (videoContainerView == nil)
        {
            print("videoContainerView not bound to storyboard")
            return
        }
        
        // Set ourself as the presenting view controller
        // so that tab bar panels can present other view controllers
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        
        // Create and add to the video container view
        playerView = BCOVTVPlayerView(options: options)
        if (playerView != nil) {
            playerView!.frame = self.videoContainerView.bounds
            self.videoContainerView.addSubview(playerView!)
        }
    }

    func createSampleTabBarItemView() {
        
        if let sampleTabBarItemView = SampleTabBarItemView(size: CGSize.init(width: 620, height: 200), playerView: playerView) {
            
            // Insert our new tab bar item view at the end of the top tab bar
            var topTabBarItemViews = playerView?.settingsView.topTabBarItemViews
            topTabBarItemViews?.append(sampleTabBarItemView)
            playerView?.settingsView.topTabBarItemViews = topTabBarItemViews
        }
        
    }

    func requestContentFromPlaybackService() {
        playbackService?.findVideo(withVideoID: kViewControllerVideoID, parameters: nil) { (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            if let v = video {
                //  since "isAutoPlay" is true, setVideos will begin playing the content
                self.playbackController.setVideos([v] as NSArray)
            } else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    // MARK: Playback controller delegate methods
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        NSLog("ViewController Debug - Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        NSLog("Event: %@", lifecycleEvent.eventType)
    }

    // MARK: UIFocusEnvironment overrides
    
    // Focus Environment override for tvOS 9
    override var preferredFocusedView: UIView? {
        return playerView
    }
    
    // Focus Environment override for tvOS 10+
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return (playerView != nil ? [ playerView! ] : [])
    }
}
