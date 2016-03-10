//
//  ViewController.swift
//  AppleTV
//
//  Created by Michael Moscardini on 3/10/16.
//  Copyright © 2016 Brightcove. All rights reserved.
//

import UIKit
import AVKit


let kViewControllerCatalogToken = "ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A.."
let kViewControllerPlaylistID = "3637400917001"


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {

    let catalogService = BCOVCatalogService(token:kViewControllerCatalogToken)
    let avpvc = AVPlayerViewController()
    let playbackController :BCOVPlaybackController
    @IBOutlet weak var videoContainerView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        let manager = BCOVPlayerSDKManager.sharedManager();
        playbackController = manager.createPlaybackControllerWithViewStrategy(manager.defaultControlsViewStrategy())
        
        super.init(coder: aDecoder)
        
        playbackController.delegate = self
        playbackController.autoAdvance = true
        playbackController.autoPlay = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.addChildViewController(self.avpvc);
        self.avpvc.view.frame = self.view.bounds;
        self.avpvc.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view.addSubview(self.avpvc.view);
        self.avpvc.didMoveToParentViewController(self);
        
        requestContentFromCatalog()
    }
    
    func requestContentFromCatalog() {
        catalogService.findPlaylistWithPlaylistID(kViewControllerPlaylistID, parameters: nil) { (playlist: BCOVPlaylist!, jsonResponse: [NSObject : AnyObject]!, error: NSError!) -> Void in
            
            if let p = playlist
            {
                self.playbackController.setVideos(p)
            }
            else
            {
                NSLog("ViewController Debug - Error retrieving playlist: %@", error)
            }
            
        }
    }
    
    func playbackController(controller: BCOVPlaybackController!, didAdvanceToPlaybackSession session: BCOVPlaybackSession!) {
        NSLog("ViewController Debug - Advanced to new session.")
        
        self.avpvc.player = session.player;
    }
    
    func playbackController(controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceiveLifecycleEvent lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        NSLog("Event: %@", lifecycleEvent.eventType)
    }

}

