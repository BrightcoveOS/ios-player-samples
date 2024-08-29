//
//  BCOVVideoPlayer.swift
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import React
import BrightcovePlayerSDK

//import BrightcoveIMA
//import GoogleInteractiveMediaAds


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"
let kVMAPAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator="



final class BCOVVideoPlayer: UIView {

    // Create the content overlay view for displaying ads (if configured)
    fileprivate lazy var contentOverlayView: UIView = {
        let contentOverlayView = UIView()
        contentOverlayView.frame = self.bounds
        contentOverlayView.autoresizingMask  = [.flexibleWidth, .flexibleHeight]

        return contentOverlayView
    }()

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        guard let sdkManager = BCOVPlayerSDKManager.sharedManager(),
              let authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
                                                         applicationId: nil) else {
            return nil
        }

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        var sessionProvider = fps

//        let useIMA = true
//
//        if useIMA {
//            let presentedViewController = RCTPresentedViewController()
//
//            let imaSettings = IMASettings()
//            imaSettings.language = NSLocale.current.languageCode!
//
//            let renderSettings = IMAAdsRenderingSettings()
//            renderSettings.linkOpenerPresentingController = presentedViewController
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
//                                                                            adContainer: contentOverlayView,
//                                                                            viewController: presentedViewController,
//                                                                            companionSlots: nil,
//                                                                            upstreamSessionProvider: fps,
//                                                                            options: imaPlaybackSessionOptions)
//            {
//                sessionProvider = imaSessionProvider
//            }
//        }

        guard let playbackController = sdkManager.createPlaybackController(with: sessionProvider,
                                                                           viewStrategy: nil) else {
            return nil
        }

        playbackController.view.frame = self.bounds
        playbackController.view.autoresizingMask  = [.flexibleWidth, .flexibleHeight]

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()

    fileprivate var thumbnailManager: BCOVThumbnailManager?

    @objc
    fileprivate(set) var onReady: RCTDirectEventBlock?

    @objc
    fileprivate(set) var onProgress: RCTDirectEventBlock?

    @objc
    fileprivate(set) var onEvent: RCTDirectEventBlock?

    init() {
        super.init(frame: .zero)

        guard let playbackController else { return }

        self.addSubview(playbackController.view)
        self.addSubview(contentOverlayView)

        requestContentFromPlaybackService()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func playPause(_ isPlaying: Bool) {
        guard let playbackController else { return }
        if isPlaying {
            playbackController.pause()
        } else {
            playbackController.play()
        }
    }

    @objc
    func thumbnailAtTime(_ value: NSNumber) -> URL? {
        guard let thumbnailManager else { return nil }

        return thumbnailManager.thumbnailAtTime(value.timeValue)
    }

    @objc
    func onSlidingComplete(_ value: NSNumber) {
        guard let playbackController else { return }

        playbackController.seek(to: value.timeValue,
                                toleranceBefore: .zero,
                                toleranceAfter: .zero,
                                completionHandler: nil)
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                    jsonResponse: [AnyHashable: Any]?,
                    error: Error?) in
            guard let playbackController,
                  let video else {
                if let error {
                    print("ViewController - Error retrieving video: \(error.localizedDescription)")
                }

                return
            }

#if targetEnvironment(simulator)
            if video.usesFairPlay,
               let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let window = appDelegate.window,
               let rootViewController = window.rootViewController {
                // FairPlay doesn't work when we're running in a simulator,
                // so put up an alert.
                let alert = UIAlertController(title: "FairPlay Warning",
                                              message: """
                                                           FairPlay only works on actual \
                                                           iOS or tvOS devices.\n
                                                           You will not be able to view \
                                                           any FairPlay content in the \
                                                           iOS or tvOS simulator.
                                                           """,
                                              preferredStyle: .alert)

                alert.addAction(.init(title: "OK", style: .default))

                DispatchQueue.main.async {
                    rootViewController.present(alert, animated: true)
                }

                return
            }
#endif

            if playbackController.thumbnailSeekingEnabled {
                handleThumbnails(for: video)
            }

            playbackController.setVideos([video] as NSFastEnumeration)
        }
    }

    fileprivate func handleThumbnails(for video: BCOVVideo) {
        if let textTracks = video.properties[kBCOVVideoPropertyKeyTextTracks] as? [[String: Any]] {
            let filtered = textTracks.filter { $0["label"] as? String == "thumbnails" }
                .sorted(by: { ($0["src"] as? String)?.compare($1["src"] as? String ?? "") == .orderedDescending })
            if filtered.count > 1,
               let textTrack = filtered.first,
               let trackSrc = textTrack["src"] as? String,
               let url = URL(string: trackSrc) {
                thumbnailManager = BCOVThumbnailManager(thumbnailsURL: url)
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension BCOVVideoPlayer: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")

        guard let onReady,
              let duration = session?.video.properties["duration"] as? TimeInterval else {
            return
        }

        var data = [ "duration": duration,
                     "isAutoPlay": NSNumber(value: controller.isAutoPlay) ] as [String: Any]

        if let thumbnailManager,
           thumbnailManager.thumbnails.count > 0 {
            let thumbnails = thumbnailManager.thumbnails.map { thumbnail in
                return ["uri": thumbnail.url?.absoluteString ]
            }

            data["thumbnails"] = thumbnails;
        }

        onReady(data)
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }

        if kBCOVPlaybackSessionLifecycleEventAdSequenceEnter == lifecycleEvent.eventType,
           let onEvent {
            onEvent([ "inAdSequence": NSNumber(value: true) ])
        }

        if kBCOVPlaybackSessionLifecycleEventAdSequenceExit == lifecycleEvent.eventType,
           let onEvent {
            onEvent([ "inAdSequence": NSNumber(value: false) ])
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didProgressTo progress: TimeInterval) {

        guard let onProgress,
              progress.isFinite else { return }

        onProgress([ "progress": NSNumber(value: progress) ])
    }
}


// MARK: - BCOVIMAPlaybackSessionDelegate

//extension BCOVVideoPlayer: BCOVIMAPlaybackSessionDelegate {
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

//extension BCOVVideoPlayer: IMALinkOpenerDelegate {
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
