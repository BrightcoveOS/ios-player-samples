//
//  PlayerViewModel.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import BrightcoveIMA
import BrightcovePlayerSDK
import Foundation
import GoogleInteractiveMediaAds
import UIKit

/// View model for the SwiftUI + Brightcove + IMA sample.
///
/// Owns the playback service, the playback controller (strong), and a
/// companion-ad-slot UIView. Forwards Brightcove and IMA delegate callbacks.
///
/// `@MainActor` documents the thread-affinity assumption: the Brightcove and
/// IMA SDKs deliver every delegate callback on the main thread, and every
/// observable mutation needs to be on the main thread for SwiftUI.
@MainActor
@Observable
final class PlayerViewModel: NSObject {

    // MARK: UI state

    private(set) var status: Status = .idle
    private(set) var isInAdSequence = false
    private(set) var currentVideoID: String?

    enum Status: Equatable {
        case idle
        case loading
        case ready
        case failed(message: String)
    }

    // MARK: Configuration

    /// Locked at construction. The IMA chain is wired exactly once for this
    /// mode in `IMAPlayerViewController.viewDidLoad`. To play with a different
    /// ad mode, the user navigates back to the configuration screen — that
    /// tears the player view controller down and rebuilds from scratch.
    let adMode: AdMode

    init(adMode: AdMode) {
        self.adMode = adMode
        super.init()
    }

    // MARK: Dependencies

    private let playbackService = BCOVPlaybackService(
        withAccountId: Config.accountID,
        policyKey: Config.policyKey
    )

    /// Set by `IMAPlayerViewController` once it has constructed the IMA-wired
    /// playback controller. Strongly retained: `BCOVPUIPlayerView` only holds
    /// the controller weakly, so the view model is the canonical owner.
    var playbackController: BCOVPlaybackController?

    /// The host view controller, set by `IMAPlayerViewController.viewDidLoad`.
    /// Used to register OMID friendly obstructions over the player chrome.
    weak var imaHost: IMAPlayerViewController?

    /// UIView that IMA renders companion ads into. Created eagerly so both
    /// `CompanionAdSlotView` (SwiftUI) and `IMAPlayerViewController.viewDidLoad`
    /// see the same instance regardless of ordering.
    let companionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground
        return view
    }()

    // MARK: Public API

    /// Surface a failure message to the UI from outside the model (e.g. from
    /// `IMAPlayerViewController` when its setup chain returns nil).
    func reportFailure(_ message: String) {
        status = .failed(message: message)
    }

    /// Fetch the requested video and load it into the playback controller.
    /// The IMA chain is unchanged — the same playback controller plays every
    /// video the user picks from the in-screen playlist.
    func load(videoID: String) {
        guard let playbackController else {
            Log.playback.error("load(videoID:) called before playbackController was set")
            status = .failed(message: "Playback controller is not ready")
            return
        }

        currentVideoID = videoID
        status = .loading
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: videoID]
        Log.playback.info("Requesting video \(videoID, privacy: .public) (mode: \(self.adMode.rawValue, privacy: .public))")

        playbackService.findVideo(withConfiguration: configuration, queryParameters: nil) { [weak self] video, _, error in
            MainActor.assumeIsolated {
                guard let self else { return }
                // If the user picked a different video before this one came
                // back, drop the stale result.
                guard self.currentVideoID == videoID else { return }

                if let error {
                    Log.playback.error("findVideo failed: \(error.localizedDescription, privacy: .public)")
                    self.status = .failed(message: error.localizedDescription)
                    return
                }
                guard let video else {
                    self.status = .failed(message: "No video returned from playback service")
                    return
                }

                #if targetEnvironment(simulator)
                if video.usesFairPlay {
                    self.status = .failed(message: "FairPlay content does not play in the iOS Simulator. Run on a physical device.")
                    return
                }
                #endif

                let prepared: BCOVVideo
                switch self.adMode {
                case .vmap:
                    prepared = video.withVMAPTag(Config.vmapAdTagURL)
                case .vast:
                    prepared = video.withVASTCuePoints(adTag: Config.vastAdTagURL)
                case .vastOM:
                    prepared = video.withVASTCuePoints(adTag: Config.omidVASTAdTagURL)
                }

                playbackController.setVideos([prepared])
                // Don't transition to `.ready` here — `setVideos()` only
                // queues. The lifecycle handler for
                // `kBCOVPlaybackSessionLifecycleEventReady` makes the move.
            }
        }
    }
}

// MARK: - BCOVPlaybackControllerDelegate

// `@preconcurrency` on each Brightcove and IMA delegate conformance below:
// these are Obj-C protocols with no actor isolation, but the SDKs document
// every callback as main-thread-delivered. The annotation lets us conform
// to them from a `@MainActor` class without spurious data-race warnings
// under Swift 6 mode.
extension PlayerViewModel: @preconcurrency BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        Log.lifecycle.info("Advanced to new playback session")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        let type = lifecycleEvent.eventType

        switch type {
        case kBCOVPlaybackSessionLifecycleEventFail:
            if let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError {
                Log.playback.error("Playback failed: \(error.localizedDescription, privacy: .public)")
                status = .failed(message: error.localizedDescription)
            }
            // Reset transient ad state so the UI doesn't say "Playing ad"
            // forever after a mid-ad failure.
            isInAdSequence = false

        case kBCOVPlaybackSessionLifecycleEventReady:
            // Promote the status to `.ready` only when the session is
            // genuinely ready — `setVideos()` only queues the asset.
            if status == .loading {
                status = .ready
            }

        case kBCOVIMALifecycleEventAdsLoaderFailed:
            let description = (lifecycleEvent.properties["error"] as? NSError)?.localizedDescription ?? "unknown"
            Log.ads.error("IMA ads loader failed: \(description, privacy: .public)")

        case kBCOVIMALifecycleEventAdsManagerDidReceiveAdError:
            let description = (lifecycleEvent.properties["error"] as? NSError)?.localizedDescription ?? "unknown"
            Log.ads.error("IMA ads manager error: \(description, privacy: .public)")

        case kBCOVIMALifecycleEventAdsLoaderLoaded:
            // Demo: lower ads volume to half. Remove for production.
            if let adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager] as? IMAAdsManager {
                adsManager.volume = adsManager.volume / 2.0
                Log.ads.info("Ads loaded; volume set to \(adsManager.volume)")
            }

        case kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent:
            if let adEvent = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdEvent] as? IMAAdEvent {
                Log.ads.info("Ad event: \(adEvent.typeString, privacy: .public)")
            }

        default:
            Log.lifecycle.debug("Lifecycle event: \(type, privacy: .public)")
        }
    }
}

// MARK: - BCOVPlaybackControllerAdsDelegate

extension PlayerViewModel: @preconcurrency BCOVPlaybackControllerAdsDelegate {

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAdSequence adSequence: BCOVAdSequence) {
        Log.ads.info("Entering ad sequence")
        isInAdSequence = true
        registerOMIDFriendlyObstructionsIfNeeded(in: session)
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAdSequence adSequence: BCOVAdSequence) {
        Log.ads.info("Exiting ad sequence")
        isInAdSequence = false
        unregisterOMIDFriendlyObstructions(in: session)
    }

    private func registerOMIDFriendlyObstructionsIfNeeded(in session: BCOVPlaybackSession) {
        guard adMode == .vastOM,
              let video = session.video,
              let container = video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer] as? IMAAdDisplayContainer else {
            return
        }
        imaHost?.registerFriendlyObstruction(in: container)
    }

    private func unregisterOMIDFriendlyObstructions(in session: BCOVPlaybackSession) {
        guard let video = session.video,
              let container = video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer] as? IMAAdDisplayContainer else {
            return
        }
        container.unregisterAllFriendlyObstructions()
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didEnterAd ad: BCOVAd) {
        Log.ads.info("Entering ad")
    }

    func playbackController(_ controller: BCOVPlaybackController,
                            playbackSession session: BCOVPlaybackSession,
                            didExitAd ad: BCOVAd) {
        Log.ads.info("Exiting ad")
    }
}

// MARK: - BCOVIMAPlaybackSessionDelegate

extension PlayerViewModel: @preconcurrency BCOVIMAPlaybackSessionDelegate {

    func willCallIMAAdsLoaderRequestAds(with adsRequest: IMAAdsRequest!,
                                        forPosition position: TimeInterval) {
        // Demo: set the VAST load timeout to 3000 ms. Adjust or remove for
        // production — the SDK ships with a sensible default.
        adsRequest.vastLoadTimeout = 3000.0
        Log.ads.debug("IMAAdsRequest at position \(position)")
    }
}

// MARK: - IMALinkOpenerDelegate

extension PlayerViewModel: @preconcurrency IMALinkOpenerDelegate {

    func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
        Log.ads.debug("In-app browser opened")
    }

    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        Log.ads.debug("In-app browser closed; resuming ad")
        playbackController?.resumeAd()
    }
}
