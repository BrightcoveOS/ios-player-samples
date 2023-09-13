//
//  PlayerModel.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.

import SwiftUI

import BrightcovePlayerSDK


final class PlayerModel: NSObject, ObservableObject, BCOVPlaybackControllerDelegate {

    @Published var duration: Double = .zero
    @Published var buffer: Double = .zero
    @Published var progress: Double = .zero
    @Published var isPlaying = false
    @Published var showControls = true

    private(set) lazy var controller: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.shared()

        let fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)!
        let basicSessionProvider = sdkManager?.createBasicSessionProvider(with:nil)
        let fairplaySessionProvider = sdkManager?.createFairPlaySessionProvider(withApplicationCertificate:nil, authorizationProxy:fairPlayAuthProxy, upstreamSessionProvider:basicSessionProvider)

        guard let _playbackController = sdkManager?.createPlaybackController(with: fairplaySessionProvider, viewStrategy: nil) else {
            return nil
        }

        _playbackController.delegate = self
        _playbackController.isAutoPlay = true
        _playbackController.isAutoAdvance = false

        return _playbackController
    }()

    private var timer: Timer?


    // MARK: BCOVPlaybackControllerDelegate

    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        if let item = session.player.currentItem {
            if item.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
                guard session.player != nil else { return }
                buffer = availableDuration(player: session.player)
            }
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        self.progress = progress
        guard !(progress.isNaN || progress.isInfinite) else { return }
        self.progress = progress.rounded()
        if let currentItem = session?.player.currentItem {
            if currentItem.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
                buffer = availableDuration(player: session.player)
            }
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didChangeDuration duration: TimeInterval) {
        self.duration = duration.rounded()
    }

    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        switch lifecycleEvent.eventType {
        case kBCOVPlaybackSessionLifecycleEventPlay:
            isPlaying = true
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] timer in
                self?.showControls = false
            }
        case kBCOVPlaybackSessionLifecycleEventPause:
            isPlaying = false
            timer?.invalidate()
            showControls = true
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


    // MARK: Private Methods

    // Buffer Refer: https://stackoverflow.com/questions/7691854/avplayer-streaming-progress
    private func availableDuration(player: AVPlayer) -> TimeInterval {
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
}
