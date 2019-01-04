//
//  ViewController.swift
//  DVRLive
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

private let kVideoURLString = ""

class ViewController: UIViewController {
    
    @IBOutlet weak var videoContainer: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let vc = BCOVPlayerSDKManager.shared()?.createPlaybackController(viewStrategy: nil) else {
            return nil
        }
        
        vc.delegate = self
        vc.isAutoAdvance = true
        vc.isAutoPlay = true
        return vc
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        
        let controlsView = BCOVPUIBasicControlView.withLiveDVRLayout()
        
        guard let playerView = BCOVPUIPlayerView(playbackController: playbackController, options: options, controlsView: controlsView) else {
            return
        }
        videoContainer.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            playerView.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ])
        playerView.playbackController = playbackController
        
        let videoURL = URL(string: kVideoURLString)
        let source = BCOVSource(url: videoURL, deliveryMethod: kBCOVSourceDeliveryHLS, properties: nil)
        let video = BCOVVideo(source: source, cuePoints: nil, properties: nil)
        playbackController?.setVideos([video] as NSFastEnumeration)
    }


}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        switch lifecycleEvent.eventType {
        case kBCOVPlaybackSessionLifecycleEventPlay:
            print("ViewController Debug - Received lifecycle play event.")
        case kBCOVPlaybackSessionLifecycleEventPause:
            print("ViewController Debug - Received lifecycle pause event.")
        default:
            break;
        }
        
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
    
}

