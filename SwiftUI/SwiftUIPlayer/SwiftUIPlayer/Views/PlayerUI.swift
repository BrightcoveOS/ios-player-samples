//
//  PlayerUI.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK
import AVKit


struct PlayerUI: UIViewRepresentable {

    var playbackController: BCOVPlaybackController?
    var playerView: BCOVPUIPlayerView
    var fullscreenEnabled = false
    var pictureInPictureEnabled = false
    
    init() {
        // Set up BCOVPlaybackController
        let fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)!
        let basicSessionProvider = BCOVPlayerSDKManager.sharedManager()?.createBasicSessionProvider(with:nil)
        let fairplaySessionProvider = BCOVPlayerSDKManager.sharedManager()?.createFairPlaySessionProvider(withApplicationCertificate:nil, authorizationProxy:fairPlayAuthProxy, upstreamSessionProvider:basicSessionProvider)
        playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: fairplaySessionProvider, viewStrategy: nil)
        
        playbackController?.isAutoPlay = true
        playbackController?.isAutoAdvance = true
        
        // Set up BCOVUIPlayerView
        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true
        
        playerView = BCOVPUIPlayerView(playbackController: playbackController, options: options, controlsView: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
   
    func makeUIView(context: Context) -> BCOVPUIPlayerView {

        self.playerView.playbackController = self.playbackController
        self.playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.playerView.delegate = context.coordinator
        
        self.playbackController?.delegate = context.coordinator
        
        return self.playerView
    }
    
    func updateUIView(_ uiView: BCOVPUIPlayerView, context: Context) {
        
    }

    class Coordinator: NSObject, BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate {

        // MARK: BCOVPlaybackControllerDelegate
    
        func playbackController(_ controller: BCOVPlaybackController?, didAdvanceTo session: BCOVPlaybackSession?) {
            print("Coordinator Debug - Advanced to new session.")
        }
        
        func playbackController(_ controller: BCOVPlaybackController?, playbackSession session: BCOVPlaybackSession?, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent?) {
            if let eventType = lifecycleEvent?.eventType {
                print("Coordinator Debug - Event Type: \(eventType)")
            }
        }
                
        // MARK: BCOVPUIPlayerViewDelegate
        
        func playerView(_ playerView: BCOVPUIPlayerView!, didTransitionTo screenMode: BCOVPUIScreenMode) {
            playerUI.fullscreenEnabled = screenMode == .full
        }

        func pictureInPictureControllerDidStartPicture(inPicture pictureInPictureController: AVPictureInPictureController!) {
            playerUI.pictureInPictureEnabled = true
        }
        
        func pictureInPictureControllerDidStopPicture(inPicture pictureInPictureController: AVPictureInPictureController!) {
            playerUI.pictureInPictureEnabled = false
        }
    }

    typealias UIViewType = BCOVPUIPlayerView
}

struct PlayerUI_Previews: PreviewProvider {
    static var previews: some View {
        PlayerUI()
    }
}
