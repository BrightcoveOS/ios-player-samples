//
//  ViewController.swift
//  BasicOUXPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveOUX

struct OUXPlayerConstants {
    static let videoURLString = "http://once.unicornmedia.com/now/ads/vmap/od/auto/c501c3ee-7f1c-4020-aa6d-0b1ef0bbd4a9/354a749c-217b-498e-b4f9-c48cd131f807/66496c0e-6969-41b1-859f-9bdf288cfdd3/content.once"
}

class ViewController: UIViewController {

    @IBOutlet var videoContainerView: UIView!
    @IBOutlet var companionSlotContainerView: UIView!
    
    var controller: BCOVPlaybackController?
    var playerView: BCOVPUIPlayerView?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a companion slot.
        let companionSlot = BCOVOUXCompanionSlot(view: companionSlotContainerView, width: 500, height: 61)
        
        // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
        let adComponentDisplayContainer = BCOVOUXAdComponentDisplayContainer(companionSlots: [companionSlot])
        
        controller = BCOVPlayerSDKManager.shared().createOUXPlaybackController(viewStrategy: nil)
        
        // In order for the ad display container to receive ad information, we add it as a session consumer.
        controller?.add(adComponentDisplayContainer)
        controller?.delegate = self
        controller?.isAutoPlay = true
        
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        
        // Set playback controller later.
        playerView = BCOVPUIPlayerView(playbackController: nil, options: nil, controlsView: controlView)
        if let playerView = playerView {
            playerView.translatesAutoresizingMaskIntoConstraints = false
            videoContainerView.addSubview(playerView)
            NSLayoutConstraint.activate([
                playerView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
                playerView.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
                playerView.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
                playerView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
            ])
            playerView.playbackController = controller
        }
        
        // Create video
        let video = BCOVVideo(url: URL(string: OUXPlayerConstants.videoURLString))
        controller?.setVideos([video] as NSFastEnumeration)
    }


}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
    
}

// MARK: - BCOVPlaybackControllerAdsDelegate

extension ViewController: BCOVPlaybackControllerAdsDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
        print("ViewController Debug - Entering ad sequence")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
        print("ViewController Debug - Exiting ad sequence")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter ad: BCOVAd!) {
        print("ViewController Debug - Entering ad")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAd ad: BCOVAd!) {
        print("ViewController Debug - Exiting ad")
    }
    
}
