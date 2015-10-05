//
//  ViewController.swift
//  VideoCloudBasicPlayer
//
//  Created by Mike Moscardini on 9/29/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

import UIKit


let kViewControllerCatalogToken = "ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A.."
let kViewControllerPlaylistID = "3637400917001"


class ViewController: UIViewController, BCOVPlaybackControllerDelegate {

    let catalogService = BCOVCatalogService(token:kViewControllerCatalogToken)
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

        playbackController.view.frame = videoContainerView.bounds
        playbackController.view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        videoContainerView.addSubview(playbackController.view)

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
    }

    // MARK: UI Styling

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

