//
//  ApplePlayerUI.swift
//  SwiftUIPlayer
//
//  Created by Jeremy Blaker on 7/26/23.
//

import SwiftUI
import BrightcovePlayerSDK
import AVKit

struct ApplePlayerUI: UIViewControllerRepresentable {
    @EnvironmentObject var modelData: ModelData

    var playbackController: BCOVPlaybackController?
    
    var avpvc = AVPlayerViewController()
    
    init() {
        // Set up BCOVPlaybackController
        let fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)!
        let basicSessionProvider = BCOVPlayerSDKManager.sharedManager()?.createBasicSessionProvider(with:nil)
        let fairplaySessionProvider = BCOVPlayerSDKManager.sharedManager()?.createFairPlaySessionProvider(withApplicationCertificate:nil, authorizationProxy:fairPlayAuthProxy, upstreamSessionProvider:basicSessionProvider)
        playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: fairplaySessionProvider, viewStrategy: nil)
        
        playbackController?.isAutoPlay = true
        playbackController?.isAutoAdvance = true
        playbackController?.options = [ kBCOVAVPlayerViewControllerCompatibilityKey : true ]
    }
    
    static func findTabBarController(children: [UIViewController]) -> UITabBarController? {
        for childVC in children {
            if let tabBarController = childVC as? UITabBarController {
                return tabBarController
            }
            return findTabBarController(children: childVC.children)
        }
        return nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(modelData: modelData, avpvc: avpvc)
    }
    
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.modalPresentationStyle = .fullScreen
        playerController.delegate = context.coordinator
        playbackController?.delegate = context.coordinator
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return avpvc
    }

    class Coordinator: NSObject, BCOVPlaybackControllerDelegate, AVPlayerViewControllerDelegate {

        var modelData: ModelData
        var avpvc: AVPlayerViewController
        
        init(modelData: ModelData, avpvc: AVPlayerViewController) {
            self.modelData = modelData
            self.avpvc = avpvc
        }

        // MARK: BCOVPlaybackControllerDelegate
    
        func playbackController(_ controller: BCOVPlaybackController?, didAdvanceTo session: BCOVPlaybackSession?) {
            print("Coordinator Debug - Advanced to new session.")
            if let player = session?.player {
                avpvc.player = player
            }
        }
        
        func playbackController(_ controller: BCOVPlaybackController?, playbackSession session: BCOVPlaybackSession?, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent?) {
            if let eventType = lifecycleEvent?.eventType {
                print("Coordinator Debug - Event Type: \(eventType)")
            }
        }
                
        // MARK: AVPlayerViewControllerDelegate
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animate { context in
                self.modelData.fullscreenEnabled = true
            }
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animate { context in
                self.modelData.fullscreenEnabled = false
            }
        }
        
        func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            modelData.pictureInPictureEnabled = true
        }
        
        func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            modelData.pictureInPictureEnabled = false
        }
    }
}
