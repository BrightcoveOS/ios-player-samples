//
//  ViewController.swift
//  Video360Player
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve and play a 360 video.
 * The code for retrieving and playing the video is identical
 * to any other code that retrieves and plays a video from Video Cloud.
 *
 * What makes this code different is the usage of the
 * BCOVPUIPlayerViewDelegate delegate method
 * `-didSetVideo360NavigationMethod:projectionStyle:`
 * This method is called when the Video 360 button is tapped, and indicates that
 * you probably want to set the device orientation to landscape if the
 * projection method has changed to VR Goggles mode.
 *
 * The code below shows how to handle changing the device orientation
 * when that delegate is called.
 */

import UIKit
import BrightcovePlayerSDK

struct ConfigConstants {
    static let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    static let AccountID = "3636334163001"
    static let VideoID = "5240309173001"
}

class ViewController: UIViewController {
    
    @IBOutlet weak var videoContainerView: UIView!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return landscapeOnly ? .landscape : .all
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    private var landscapeOnly = false
    
    private lazy var playerView: BCOVPUIPlayerView? = {
        // Create PlayerUI views with normal VOD controls.
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: nil, controlsView: controlView) else {
            return nil
        }

        // Add to parent view
        self.videoContainerView.addSubview(_playerView)
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
        ])
        
        // Receive delegate method callbacks
        _playerView.delegate = self
        
        return _playerView
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController() else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
    private lazy var playbackService: BCOVPlaybackService = {
        return BCOVPlaybackService(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PlaybackServicePolicyKey)
    }()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestContentFromPlaybackService()
    }
    
    // MARK: - Misc
    
    private func requestContentFromPlaybackService() {
        
        playbackService.findVideo(withVideoID: ConfigConstants.VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            if let projectionPropertyString = video?.properties["projection"] as? String {
                // Check "projection" property to confirm that this is a 360 degree video
                
                if projectionPropertyString == "equirectangular" {
                    print("Retrieved a 360 video")
                }
                
                self?.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            
            if let error = error {
                print("Error retrieving video: \(error.localizedDescription)")
            }
            
        }
        
    }
    
    private func handleOrientationForGoggles() {
        
        let current = UIDevice.current.orientation
        
        switch current {
        case .landscapeLeft, .landscapeRight:
            // Already landscape
            break
        default:
            // Switch orientation
            let value = NSNumber(value: UIInterfaceOrientation.landscapeLeft.rawValue)
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        
        UIViewController.attemptRotationToDeviceOrientation()
        
    }
    
}

// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {
    
    func didSetVideo360NavigationMethod(_ navigationMethod: BCOVPUIVideo360NavigationMethod, projectionStyle: BCOVVideo360ProjectionStyle) {
        
        // This method is called when the Video 360 button is tapped.
        // Use this notification to force an orientation change for the VR Goggles projection style.
        
        switch projectionStyle {
            case .normal:
                print("projectionStyle == BCOVVideo360ProjectionStyleNormal")
                
                // No landscape restriction
                self.landscapeOnly = false
            case .vrGoggles:
                print("projectionStyle == BCOVVideo360ProjectionStyleVRGoggles")
            
                // Allow only landscape if wearing goggles
                self.landscapeOnly = true
                
                // If the goggles are on, change the device orientation
                self.handleOrientationForGoggles()
        }
        
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, didCompletePlaylist playlist: NSFastEnumeration!) {
        // Play it again
        controller.setVideos(playlist)
    }
    
}
