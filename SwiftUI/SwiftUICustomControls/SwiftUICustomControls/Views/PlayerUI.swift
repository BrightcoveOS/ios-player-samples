//
//  PlayerUI.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK
import SwiftUI

struct PlayerUI: UIViewRepresentable {
    @EnvironmentObject var playerStateModelData: PlayerStateModelData
    var playbackController: BCOVPlaybackController?

    init() {
        // Set up BCOVPlaybackController
        let fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)!
        let basicSessionProvider = BCOVPlayerSDKManager.sharedManager()?.createBasicSessionProvider(with:nil)
        let fairplaySessionProvider = BCOVPlayerSDKManager.sharedManager()?.createFairPlaySessionProvider(withApplicationCertificate:nil, authorizationProxy:fairPlayAuthProxy, upstreamSessionProvider:basicSessionProvider)
        playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: fairplaySessionProvider, viewStrategy: nil)
        
        playbackController?.isAutoPlay = true
        playbackController?.isAutoAdvance = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(playerStateModelData: playerStateModelData)
    }

    func makeUIView(context: Context) -> UIView {
        self.playbackController?.delegate = context.coordinator
        return self.playbackController?.view ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }

    class Coordinator: NSObject, BCOVPlaybackControllerDelegate {
        var playerStateModelData: PlayerStateModelData
        
        init(playerStateModelData: PlayerStateModelData) {
            self.playerStateModelData = playerStateModelData
        }
        
        // Buffer Can Caclutor Refer: https://stackoverflow.com/questions/7691854/avplayer-streaming-progress
        func availableDuration(player: AVPlayer) -> TimeInterval {
            let loadedTimeRanges = player.currentItem?.loadedTimeRanges
            let timeRange = loadedTimeRanges?.first?.timeRangeValue
            var startSeconds: Float64? = nil
            if let start = timeRange?.start {
                startSeconds = CMTimeGetSeconds(start)
            }
            var durationSeconds: Float64? = nil
            if let duration = timeRange?.duration {
                durationSeconds = CMTimeGetSeconds(duration)
            }
            let result = TimeInterval((startSeconds ?? 0) + (durationSeconds ?? 0))
            return result
        }

        // BCOVPlaybackController Protocol
        func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
            if let item = session.player.currentItem {
                if item.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
                    guard session.player != nil else { return }
                    playerStateModelData.buffer = availableDuration(player: session.player)
                }
            }
        }

        func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
            playerStateModelData.progress = progress
            guard !(progress.isNaN || progress.isInfinite) else {
                return
            }
            playerStateModelData.progress = progress.rounded()
            if let currentItem = session?.player.currentItem {
                if currentItem.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
                    playerStateModelData.buffer = availableDuration(player: session.player)
                }
            }
        }

        func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didChangeDuration duration: TimeInterval) {
            playerStateModelData.duration = duration.rounded()
        }

        func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

            switch lifecycleEvent.eventType {
            case kBCOVPlaybackSessionLifecycleEventPlay:
                playerStateModelData.isPlaying = true
            case kBCOVPlaybackSessionLifecycleEventPause:
                playerStateModelData.isPlaying = false
            case kBCOVPlaybackSessionLifecycleEventResumeFail:
                print("resumeFail")
            case kBCOVPlaybackSessionLifecycleEventResumeBegin:
                print("play")
            case kBCOVPlaybackSessionLifecycleEventFail:
                print("failedToLoad")
            case kBCOVPlaybackSessionLifecycleEventError:
                print("error")
            case kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty:
                print("bufferEmpty")
            case kBCOVPlaybackSessionLifecycleEventPlaybackLikelyToKeepUp:
                print("likelyToKeepUp")
            default: break
            }
        }
    }

    typealias UIViewType = UIView
}
