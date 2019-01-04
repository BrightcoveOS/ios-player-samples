//
//  ViewController.swift
//  NativeControls
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import AVKit

struct NativeControlsConstants {
    static let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    static let AccountID = "3636334163001"
    static let VideoID = "3666678807001"
}

class ViewController: UIViewController {
    
    let manager: BCOVPlayerSDKManager = BCOVPlayerSDKManager.shared()
    let avpvc: AVPlayerViewController = AVPlayerViewController()
    
    var playbackService: BCOVPlaybackService?
    var playbackController: BCOVPlaybackController?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet var videoContainer: UIView!
    
    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(avpvc)
        videoContainer.addSubview(avpvc.view)
        avpvc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avpvc.view.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            avpvc.view.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            avpvc.view.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            avpvc.view.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ])
        avpvc.didMove(toParent: self)
        
        requestContentFromPlaybackService()
    }

    // MARK: - Helper Methods
    
    private func setup() {
        
        playbackController = manager.createPlaybackController()
        playbackController?.delegate = self
        playbackController?.isAutoAdvance = true
        playbackController?.isAutoPlay = true
        
        // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
        // since the AVPlayerViewController already makes one
        playbackController?.options = [ kBCOVAVPlayerViewControllerCompatibilityKey : true ]
        
        playbackService = BCOVPlaybackService(accountId: NativeControlsConstants.AccountID, policyKey: NativeControlsConstants.PlaybackServicePolicyKey)
        
    }
    
    private func requestContentFromPlaybackService() {
        
        playbackService?.findVideo(withVideoID: NativeControlsConstants.VideoID, parameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable : Any]?, error: Error?) in
            
            if let strongSelf = self, let video = video {
                strongSelf.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            
            if let error = error {
                print("ViewController Debug - Error retrieving video playlist: \(error.localizedDescription)")
            }
            
        })
        
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
        avpvc.player = session.player
    }
    
}
