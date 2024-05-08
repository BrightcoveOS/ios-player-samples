//
//  PlayerModel.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


final class PlayerModel: NSObject, ObservableObject {

    @Published
    var duration = Double.zero

    @Published
    var buffer = Double.zero

    @Published
    var progress = Double.zero

    @Published
    var isPlaying = false

    @Published
    var isShowThumbnail = false

    @Published
    var showControls = true

    var thumbnailManager: ThumbnailManager?

    fileprivate var timer: Timer?

    fileprivate(set) lazy var playbackController: BCOVPlaybackController? = {
        guard let sdkManager = BCOVPlayerSDKManager.sharedManager(),
              let authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
                                                         applicationId: nil) else {
            return nil
        }

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playbackController = sdkManager.createPlaybackController(with: fps,
                                                                           viewStrategy: nil) else {
            return nil
        }

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()

    // Buffer Refer: https://stackoverflow.com/questions/7691854/avplayer-streaming-progress
    fileprivate func availableDuration(player: AVPlayer) -> TimeInterval {
        let loadedTimeRanges = player.currentItem?.loadedTimeRanges
        let timeRange = loadedTimeRanges?.first?.timeRangeValue

        var startSeconds = Float64.zero
        var durationSeconds = Float64.zero

        if let start = timeRange?.start {
            startSeconds = CMTimeGetSeconds(start)
        }

        if let duration = timeRange?.duration {
            durationSeconds = CMTimeGetSeconds(duration)
        }

        let result = TimeInterval(startSeconds + durationSeconds)

        return result
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension PlayerModel: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")
        if let item = session.player.currentItem,
           item.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
            guard session.player != nil else { return }
            buffer = availableDuration(player: session.player)
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didProgressTo progress: TimeInterval) {
        guard progress.isFinite else { return }
        self.progress = progress.rounded()
        if let currentItem = session?.player.currentItem,
           currentItem.responds(to: NSSelectorFromString("preferredForwardBufferDuration")) {
            buffer = availableDuration(player: session.player)
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didChangeDuration duration: TimeInterval) {
        self.duration = duration.rounded()
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        switch lifecycleEvent.eventType {
            case kBCOVPlaybackSessionLifecycleEventPlay:
                isPlaying = true
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 2,
                                             repeats: false) { [weak self] timer in
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
}
