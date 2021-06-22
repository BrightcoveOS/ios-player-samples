//
//  PlayerUI.swift
//  SwiftUIPlayer
//
//  Created by Carlos Ceja.
//

import SwiftUI

import BrightcovePlayerSDK


struct PlayerUI: UIViewRepresentable {

    var playbackController: BCOVPlaybackController
    var playerView: BCOVPUIPlayerView
    
    init(_ playbackController: BCOVPlaybackController, _ playerView: BCOVPUIPlayerView) {

        self.playbackController = playbackController
        self.playerView = playerView

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
   
    func makeUIView(context: Context) -> BCOVPUIPlayerView {

        self.playerView.playbackController = self.playbackController
        self.playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.playbackController.delegate = context.coordinator

        return self.playerView
    }
    
    func updateUIView(_ uiView: BCOVPUIPlayerView, context: Context) {
        
    }
    
    class Coordinator: NSObject, BCOVPlaybackControllerDelegate {
        
        func playbackController(_ controller: BCOVPlaybackController?, didAdvanceTo session: BCOVPlaybackSession?) {
            print("Coordinator Debug - Advanced to new session.")
        }
        
        func playbackController(_ controller: BCOVPlaybackController?, playbackSession session: BCOVPlaybackSession?, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent?) {
            if let eventType = lifecycleEvent?.eventType {
                print("Coordinator Debug - Event Type: \(eventType)")
            }
        }
    }
    
    typealias UIViewType = BCOVPUIPlayerView
}

struct PlayerUI_Previews: PreviewProvider {
    
    static var playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController()
    static var playerView = BCOVPUIPlayerView(playbackController: playbackController)
    
    static var previews: some View {
        PlayerUI(playbackController!, playerView!)
    }
}
