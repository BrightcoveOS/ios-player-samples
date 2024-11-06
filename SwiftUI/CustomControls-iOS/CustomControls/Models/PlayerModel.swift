//
//  PlayerModel.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK
//import BrightcoveIMA
//import GoogleInteractiveMediaAds

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
    
    @Published
    var inAdSequence = false

    var thumbnailManager: ThumbnailManager?

    var contentOverlayViewContainer = VideoContainerView(view: UIView())

    fileprivate var timer: Timer?

    fileprivate(set) lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)
        
        var sessionProvider = fps

//        let useIMA = true
//        
//        if useIMA {
//            let imaSettings = IMASettings()
//            imaSettings.language = NSLocale.current.languageCode!
//            
//            let renderSettings = IMAAdsRenderingSettings()
//            renderSettings.linkOpenerDelegate = self
//            
//            let adsRequestPolicy = BCOVIMAAdsRequestPolicy(vmapAdTagUrl: kVMAPAdTagURL)
//
//            // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
//            // which allows us to modify the IMAAdsRequest object before it is used to load ads.
//            let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]
//            
//            if let imaSessionProvider = sdkManager.createIMASessionProvider(with: imaSettings,
//                                                                            adsRenderingSettings: renderSettings,
//                                                                            adsRequestPolicy: adsRequestPolicy,
//                                                                            adContainer: contentOverlayViewContainer.view!,
//                                                                            viewController: rootViewController(),
//                                                                            companionSlots: nil,
//                                                                            upstreamSessionProvider: fps,
//                                                                            options: imaPlaybackSessionOptions)
//            {
//                sessionProvider = imaSessionProvider
//            }
//        }
        
        let playbackController = sdkManager.createPlaybackController(withSessionProvider: sessionProvider,
                                                                           viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()
    
    fileprivate func rootViewController() -> UIViewController? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            return rootViewController
        }
        return nil
    }

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
            case kBCOVPlaybackSessionLifecycleEventAdSequenceEnter:
                inAdSequence = true
                // Hide the controls as soon as we enter an ads sequence
                showControls = false
            case kBCOVPlaybackSessionLifecycleEventAdSequenceExit:
                inAdSequence = false
            default: break
        }
    }
}

// MARK: - BCOVIMAPlaybackSessionDelegate

//extension PlayerModel: BCOVIMAPlaybackSessionDelegate {
//
//    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!,
//                                        forPosition position: TimeInterval) {
//        // for demo purposes, increase the VAST ad load timeout.
//        adsRequest.vastLoadTimeout = 3000.0
//        print("ViewController - IMAAdsRequest.vastLoadTimeout set to \(String(format: "%.1f", adsRequest.vastLoadTimeout)) milliseconds.")
//    }
//
//}

// MARK: - IMALinkOpenerDelegate

//extension PlayerModel: IMALinkOpenerDelegate {
//
//    func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
//        print("ViewController - linkOpenerDidOpen")
//    }
//
//    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
//        print("ViewController - linkOpenerDidClose")
//
//        // Called when the in-app browser has closed.
//        guard let playbackController else { return }
//        playbackController.resumeAd()
//    }
//
//}
