//
//  ViewController.swift
//  NativeControlsIMAPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to play IMA ads with Apple's native
 * `AVPlayerViewController` transport controls on tvOS.
 *
 * A VMAP ad tag is attached to the `BCOVVideo` under `kBCOVIMAAdTag`, so the
 * BCOVIMA plugin schedules the ad breaks. The native playback controls are
 * hidden while an ad sequence plays and restored when it ends, and the video's
 * title, description, and poster are surfaced in the tvOS Info panel as
 * external metadata.
 */

import AppTrackingTransparency
import UIKit
import GoogleInteractiveMediaAds
import BrightcoveIMA


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"

let kVMAPAdTagURL = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1"


final class ViewController: UIViewController {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playerViewController: AVPlayerViewController = {
        let playerViewController = AVPlayerViewController()
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        playerViewController.didMove(toParent: self)
        return playerViewController
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                   applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode ?? "en"

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self

        // Use the VMAP ads policy.
        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()

        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
        // which allows us to modify the IMAAdsRequest object before it is used to load ads.
        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self]

        guard let imaSessionProvider = sdkManager.createIMASessionProvider(with: imaSettings,
                                                                           adsRenderingSettings: renderSettings,
                                                                           adsRequestPolicy: adsRequestPolicy,
                                                                           adContainer: playerViewController.contentOverlayView,
                                                                           viewController: playerViewController,
                                                                           companionSlots: nil,
                                                                           upstreamSessionProvider: fps,
                                                                           options: imaPlaybackSessionOptions) else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: imaSessionProvider,
                                                                     viewStrategy: nil)

        // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
        // since the AVPlayerViewController already makes one
        playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: true]

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestTrackingAuthorization),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc
    fileprivate func requestTrackingAuthorization() {
        if #available(tvOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { [self] in
                    // Tracking authorization completed.
                    // Start loading ads here.
                    requestContentFromPlaybackService()
                }
            }
        } else {
            requestContentFromPlaybackService()
        }

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [weak self] (video: BCOVVideo?,
                         jsonResponse: Any?,
                         error: Error?) in
            guard let self,
                  let video,
                  let playbackController else {
                if let error {
                    print("ViewController - Error retrieving video: \(error.localizedDescription)")
                }

                return
            }

#if targetEnvironment(simulator)
            if video.usesFairPlay {
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
                    self.present(alert, animated: true)
                }

                return
            }
#endif

            let updatedVideo = updateVideoWithVMAPTag(video)
            playbackController.setVideos([updatedVideo])
        }
    }

    fileprivate func updateVideoWithVMAPTag(_ video: BCOVVideo) -> BCOVVideo {
        video.update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo else { return }

            // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
            // the video's properties when using server side ad rules. This URL returns
            // a VMAP response that is handled by the Google IMA library.
            var updatedProperties = mutableVideo.properties
            updatedProperties[kBCOVIMAAdTag] = kVMAPAdTagURL
            mutableVideo.properties = updatedProperties
        }
    }

    fileprivate func buildMetadata(forVideo video: BCOVVideo) -> [AVMetadataItem] {
        // https://developer.apple.com/documentation/avkit/adding_information_to_the_info_panel_tvos/presenting_metadata_in_the_tvos_info_panel

        var metadataArray = [AVMetadataItem]()

        // Title
        if let title = video.properties[BCOVVideo.PropertyKeyName] as? String {
            metadataArray.append(makeMetadataItem(withIdentifier: AVMetadataIdentifier.commonIdentifierTitle,
                                                  andValue: title))
        }

        // Desc
        if let desc = video.properties[BCOVVideo.PropertyKeyDescription] as? String {
            metadataArray.append(makeMetadataItem(withIdentifier: AVMetadataIdentifier.commonIdentifierDescription,
                                                  andValue: desc))
        }

        // Poster
        if let posterURLString = video.properties[BCOVVideo.PropertyKeyPoster] as? String,
           let posterURL = URL(string: posterURLString) {
            do {
                let posterData = try Data(contentsOf: posterURL)
                metadataArray.append(makeMetadataItem(withIdentifier: AVMetadataIdentifier.commonIdentifierArtwork,
                                                      andValue: posterData))
            } catch {
                print("Error fetching poster image data: \(error)")
            }
        }

        return metadataArray
    }

    fileprivate func makeMetadataItem(withIdentifier identifier: AVMetadataIdentifier,
                                      andValue value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        guard let video = session.video,
              let player = session.player,
              let currentItem = player.currentItem else {
            return
        }

        // Set the external metadata for the info view
        DispatchQueue.global(qos: .background).async { [self] in
            currentItem.externalMetadata = buildMetadata(forVideo: video)
        }

        // Set the player on the AVPlayerViewController to begin playback
        playerViewController.player = player
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }

        // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
        // The events are defined in BCOVIMAComponent.h.
        if kBCOVIMALifecycleEventAdsLoaderLoaded == lifecycleEvent.eventType,
           let adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager] as? IMAAdsManager {
            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0
            print("ViewController - IMAAdsManager.volume set to \(String(format: "%0.1f", adsManager.volume))")

        } else if kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent == lifecycleEvent.eventType,
                  let adEvent = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdEvent] as? IMAAdEvent {
            switch adEvent.type {
                case .STARTED:
                    print("ViewController - Ad Started.")
                case .COMPLETE:
                    print("ViewController - Ad Completed.")
                case .ALL_ADS_COMPLETED:
                    print("ViewController - All ads completed.")
                default:
                    break
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerAdsDelegate

extension ViewController: BCOVPlaybackControllerAdsDelegate {

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAdSequence adSequence: BCOVAdSequence) {
        playerViewController.showsPlaybackControls = false
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAdSequence adSequence: BCOVAdSequence) {
        playerViewController.showsPlaybackControls = true
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAd ad: BCOVAd) {
        print("ViewController - Entering ad")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAd ad: BCOVAd) {
        print("ViewController - Exiting ad")
    }
}


// MARK: - BCOVIMAPlaybackSessionDelegate

extension ViewController: BCOVIMAPlaybackSessionDelegate {

    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!,
                                        forPosition position: TimeInterval) {
        // for demo purposes, increase the VAST ad load timeout.
        adsRequest.vastLoadTimeout = 3000.0
        print("ViewController - IMAAdsRequest.vastLoadTimeout set to \(String(format: "%.1f", adsRequest.vastLoadTimeout)) milliseconds.")
    }
}
