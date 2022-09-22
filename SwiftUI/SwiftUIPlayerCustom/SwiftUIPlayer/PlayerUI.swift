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
    @Binding var isPlay: Bool
    var playbackController: BCOVPlaybackController
    var playerView: BCOVPUIPlayerView

    init(
        _ playbackController: BCOVPlaybackController,
        _ playerView: BCOVPUIPlayerView,
        duration: Binding<Double>,
        bufffer: Binding<Double>,
        progress: Binding<Double>,
        isPlay: Binding<Bool>
    ) {
        self.playbackController = playbackController
        self.playerView = playerView
        _duration = duration
        _bufffer = bufffer
        _progress = progress
        _isPlay = isPlay
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(duration: $duration, bufffer: $bufffer, progress: $progress, isPlay: $isPlay)
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
        @Binding var duration: Double
        @Binding var bufffer: Double
        @Binding var progress: Double
        @Binding var isPlay: Bool

        init(
            duration: Binding<Double>,
            bufffer: Binding<Double>,
            progress: Binding<Double>,
            isPlay: Binding<Bool>
        ) {
            _duration = duration
            _bufffer = bufffer
            _progress = progress
            _isPlay = isPlay
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
        func playbackController(
            _ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!
        ) {
            if let item = session.player.currentItem {
                if item.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
                    guard session.player != nil else { return }
                    bufffer = availableDuration(player: session.player)
                }
            }
        }
        func playbackController(
            _ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!,
            didProgressTo progress: TimeInterval
        ) {
            self.progress = progress
            guard !(progress.isNaN || progress.isInfinite) else {
                return
            }
            self.progress = progress.rounded()
            if let currentItem = session?.player.currentItem {
                if currentItem.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
                    bufffer = availableDuration(player: session.player)
                }
            }
        }

        func playbackController(
            _ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!,
            didChangeDuration duration: TimeInterval
        ) {
            self.duration = duration.rounded()
        }

        func playbackController(
            _ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!,
            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!
        ) {

            switch lifecycleEvent.eventType {
            case kBCOVPlaybackSessionLifecycleEventPlay:
                isPlay = true
            case kBCOVPlaybackSessionLifecycleEventPause:
                isPlay = false
            case kBCOVPlaybackSessionLifecycleEventResumeFail:
                print("resumeFail")
            case kBCOVPlaybackSessionLifecycleEventResumeBegin:
                print("play")
            case kBCOVPlaybackSessionLifecycleEventFail:
                print("failedToLoad")
            case kBCOVPlaybackSessionLifecycleEventError:
                print("error")
            case kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty:
                do {
                    guard !(self.progress.isNaN || self.progress.isInfinite) else {
                        break
                    }
                }
            case kBCOVPlaybackSessionLifecycleEventPlaybackLikelyToKeepUp:
                do {
                    guard !(self.progress.isNaN || self.progress.isInfinite) else {
                        break
                    }
                }
            default: break
            }
        }
    }

    typealias UIViewType = BCOVPUIPlayerView
}
