//
//  BCOVVideoPlayer.swift
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AVFoundation
import AVKit
import Foundation
import Flutter
import BrightcovePlayerSDK
//import BrightcoveIMA
//import GoogleInteractiveMediaAds


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"
let kVMAPAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator="


final class BCOVVideoPlayer: NSObject {

    // Create the container that will contain the player and content overlay views
    fileprivate lazy var containerView = UIView()

    // Create the content overlay view for displaying ads (if configured)
    fileprivate lazy var contentOverlayView: UIView = {
        let contentOverlayView = UIView()
        contentOverlayView.frame = containerView.bounds
        contentOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return contentOverlayView
    }()

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
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
        //            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let flutterViewController = appDelegate.flutterViewController else {
        //                return nil
        //            }
        //
        //            let imaSettings = IMASettings()
        //            imaSettings.language = NSLocale.current.languageCode!
        //
        //            let renderSettings = IMAAdsRenderingSettings()
        //            renderSettings.linkOpenerPresentingController = flutterViewController
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
        //                                                                            viewController: flutterViewController,
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

        playbackController.view.frame = containerView.bounds
        playbackController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]


        return playbackController
    }()

    fileprivate var thumbnailManager: BCOVThumbnailManager?

    fileprivate lazy var appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate

    fileprivate lazy var methodChannel: FlutterMethodChannel? = {
        guard let flutterEngine = appDelegate?.flutterEngine else { return nil }

        return .init(name: "bcov.flutter/method_channel",
                     binaryMessenger: flutterEngine.binaryMessenger)
    }()

    fileprivate lazy var eventChannel: FlutterEventChannel? = {
        guard let flutterEngine = appDelegate?.flutterEngine else { return nil }

        return .init(name: "bcov.flutter/event_channel",
                     binaryMessenger: flutterEngine.binaryMessenger,
                     codec: FlutterJSONMethodCodec.sharedInstance())
    }()

    fileprivate var eventSink: FlutterEventSink?

    init(frame: CGRect,
         viewId: Int64,
         args: Any?) {
        super.init()

        guard let eventChannel,
              let methodChannel,
              let playbackController else {
            return
        }

        eventChannel.setStreamHandler(self)

        methodChannel.setMethodCallHandler {
            [self] (call: FlutterMethodCall,
                    result: @escaping FlutterResult) -> Void in
            handle(call, result: result)
        }

        containerView.addSubview(playbackController.view)
        containerView.addSubview(contentOverlayView)

        requestContentFromPlaybackService()
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                    jsonResponse: Any?,
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
               let appDelegate,
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

            playbackController.setVideos([video])
        }
    }

    fileprivate func handleThumbnails(for video: BCOVVideo) {
        if let textTracks = video.properties[BCOVVideo.PropertyKeyTextTracks] as? [[String: Any]] {
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

    fileprivate func handle(_ call: FlutterMethodCall,
                            result: @escaping FlutterResult) {

        guard let playbackController else {
            result(FlutterMethodNotImplemented)
            return
        }

        switch (call.method) {
            case "playPause":
                if let isPlaying = call.arguments as? Bool {
                    if isPlaying {
                        playbackController.pause()
                    } else {
                        playbackController.play()
                    }
                }
                result(nil)
                break

            case "seek":
                if let seconds = call.arguments as? TimeInterval {
                    let seekTo = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
                    playbackController.seek(to: seekTo,
                                            toleranceBefore: .zero,
                                            toleranceAfter: .zero,
                                            completionHandler: nil)
                }
                result(nil)
                break

            case "thumbnailAtTime":
                if let seconds = call.arguments as? TimeInterval {
                    let thumbnailTime = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
                    if let thumbnailManager,
                       let url = thumbnailManager.thumbnailAtTime(thumbnailTime) {
                        result(url.absoluteString)
                    }
                }
                break

            default:
                result(FlutterMethodNotImplemented)
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension BCOVVideoPlayer: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")

        guard let eventSink,
              let duration = session.video.properties[BCOVVideo.PropertyKeyDuration] as? TimeInterval else {
            return
        }

        eventSink([ "name": "didAdvanceToPlaybackSession",
                    "duration": duration,
                    "isAutoPlay": controller.isAutoPlay ])
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }

        if kBCOVPlaybackSessionLifecycleEventEnd == lifecycleEvent.eventType,
           let eventSink {
            eventSink([ "name": "eventEnd" ])
        }

        if kBCOVPlaybackSessionLifecycleEventAdSequenceEnter == lifecycleEvent.eventType,
           let eventSink {
            eventSink([ "name": "eventAdSequenceEnter" ])
        }

        if kBCOVPlaybackSessionLifecycleEventAdSequenceExit == lifecycleEvent.eventType,
           let eventSink {
            eventSink([ "name": "eventAdSequenceExit" ])
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didProgressTo progress: TimeInterval) {
        guard let eventSink,
              progress.isFinite else { return }

        eventSink([ "name": "didProgressTo",
                    "progress": progress ])
    }
}


// MARK: - FlutterPlatformView

extension BCOVVideoPlayer: FlutterPlatformView {

    func view() -> UIView {
        return containerView
    }
}


// MARK: - FlutterStreamHandler

extension BCOVVideoPlayer: FlutterStreamHandler {

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
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
