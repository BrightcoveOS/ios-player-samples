//
//  ViewController.swift
//  CustomControls
//
//  Copyright © 2018 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

fileprivate struct ConfigConstants {
    static let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    static let AccountID = "3636334163001"
    static let VideoID = "3666678807001"
}

class ViewController: UIViewController {
    
    @IBOutlet private var videoContainer: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private lazy var playbackService: BCOVPlaybackService = {
       return BCOVPlaybackService(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PlaybackServicePolicyKey)
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let vc = BCOVPlayerSDKManager.shared()?.createPlaybackController() else {
            return nil
        }
        vc.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        vc.delegate = self
        vc.isAutoAdvance = true
        vc.isAutoPlay = true
        vc.allowsExternalPlayback = true
        vc.add(self.controlsViewController)
        return vc
    }()
    
    private lazy var videoView: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()
    
    private lazy var controlsViewController: ControlsViewController = {
        let vc = ControlsViewController()
        vc.delegate = self
        return vc
    }()
    
    private lazy var fullscreenViewController: UIViewController = {
       return UIViewController()
    }()

    // MARK: - View Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let playbackController = playbackController else {
            return
        }
        
        playbackController.view.frame = videoView.bounds
        videoView.addSubview(playbackController.view)
        
        addChild(controlsViewController)
        controlsViewController.view.frame = videoView.bounds
        videoView.addSubview(controlsViewController.view)
        controlsViewController.didMove(toParent: self)
        
        videoView.frame = videoContainer.bounds
        videoContainer.addSubview(videoView)
        
        requestContentFromPlaybackService()
    }
    
    // MARK: - Misc
    
    private func requestContentFromPlaybackService() {
        playbackService.findVideo(withVideoID: ConfigConstants.VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, json: [AnyHashable:Any]?, error: Error?) in
            
            if let video = video {
                self?.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            
            if let error = error {
                print("ViewController Debug - Error retrieving video playlist: \(error.localizedDescription)")
            }
            
        }
    }


}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
    
}

// MARK: - ControlsViewControllerFullScreenDelegate

extension ViewController: ControlsViewControllerFullScreenDelegate {
    
    func handleExitFullScreenButtonPressed() {
        dismiss(animated: false) {
            
            self.videoView.frame = self.videoContainer.bounds
            self.addChild(self.controlsViewController)
            self.videoContainer.addSubview(self.videoView)
            self.controlsViewController.didMove(toParent: self)
            
        }
    }
    
    func handleEnterFullScreenButtonPressed() {
        fullscreenViewController.addChild(controlsViewController)
        videoView.frame = fullscreenViewController.view.bounds
        fullscreenViewController.view.addSubview(videoView)
        controlsViewController.didMove(toParent: fullscreenViewController)
        
        present(fullscreenViewController, animated: false, completion: nil)
    }
    
}


