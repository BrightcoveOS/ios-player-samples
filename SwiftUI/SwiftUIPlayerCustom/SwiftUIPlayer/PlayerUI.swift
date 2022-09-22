//
//  PlayerUI.swift
//  SwiftUIPlayer
//
//  Created by Carlos Ceja.
//

import BrightcovePlayerSDK
import SwiftUI

struct PlayerUI: UIViewRepresentable {
    @Binding var duration: Double
    @Binding var bufffer: Double
    @Binding var progress: Double

    var playbackController: BCOVPlaybackController
    var playerView: BCOVPUIPlayerView

    init(
        _ playbackController: BCOVPlaybackController, _ playerView: BCOVPUIPlayerView,
        duration: Binding<Double>,
        bufffer: Binding<Double>,
        progress: Binding<Double>
    ) {

        self.playbackController = playbackController
        self.playerView = playerView
        _duration = duration
        _bufffer = bufffer
        _progress = progress
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

        func playbackController(
            _ controller: BCOVPlaybackController?, didAdvanceTo session: BCOVPlaybackSession?
        ) {
            print("Coordinator Debug - Advanced to new session.")
        }

        func playbackController(
            _ controller: BCOVPlaybackController?, playbackSession session: BCOVPlaybackSession?,
            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent?
        ) {
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
