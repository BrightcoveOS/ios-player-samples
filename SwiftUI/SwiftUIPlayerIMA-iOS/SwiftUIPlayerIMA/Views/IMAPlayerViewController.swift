//
//  IMAPlayerViewController.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import AppTrackingTransparency
import BrightcoveIMA
import BrightcovePlayerSDK
import GoogleInteractiveMediaAds
import UIKit

/// `BCOVPUIPlayerViewController` subclass that builds the FairPlay → IMA → playback
/// controller chain in `viewDidLoad`, then assigns the controller to its own player view.
///
/// Why subclass `BCOVPUIPlayerViewController` and not compose? IMA needs a real
/// `UIViewController` ancestor for ad presentation, and the SDK header documents
/// this as the SwiftUI-recommended host. The view controller needs to exist
/// before the IMA chain can be wired (the chain references `self` and
/// `playerView.contentOverlayView`), and it needs to be in a view hierarchy by
/// the time IMA presents an in-app browser — `viewDidLoad` satisfies both.
final class IMAPlayerViewController: BCOVPUIPlayerViewController {

    private let viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel

        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true

        // The SDK header documents `playbackController` as non-nil, but
        // accepts nil at runtime. We need it to be nil here because the
        // IMA chain (built in `viewDidLoad`) needs `self` and
        // `playerView.contentOverlayView` — neither exists until the
        // super-init returns. We assign the controller back to
        // `playerView.playbackController` after the chain is built.
        super.init(playbackController: nil, options: options, controlsView: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("IMAPlayerViewController must be created with init(viewModel:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.imaHost = self

        guard let playbackController = makePlaybackController() else {
            Log.session.error("Failed to construct IMA playback controller")
            viewModel.reportFailure("Failed to construct IMA playback controller")
            return
        }

        playbackController.delegate = viewModel
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsBackgroundAudioPlayback = true
        playbackController.allowsExternalPlayback = true

        playerView.playbackController = playbackController

        viewModel.playbackController = playbackController

        // Resolve ATT before the first IMA ad request, then load the first
        // video. The system prompts only the first time and returns cached
        // status afterward. Doing this in `viewDidLoad` rather than from a
        // SwiftUI `.task` modifier matters: `.task` re-fires when the view
        // re-appears after a modal dismiss (e.g. IMA's clickthrough
        // browser), which would re-trigger `load(videoID:)` and restart
        // playback.
        Task { @MainActor in
            let status = await ATTrackingManager.requestTrackingAuthorization()
            Log.session.info("ATT status: \(status.rawValue, privacy: .public)")
            if let firstVideoID = Config.demoVideos.first?.id {
                viewModel.load(videoID: firstVideoID)
            }
        }
    }

    /// Tear the player down so SwiftUI can release the view controller and
    /// view model when the user navigates away. The IMA session provider
    /// keeps its session delegate (`viewModel`, registered via
    /// `kBCOVIMAOptionIMAPlaybackSessionDelegateKey`) alive for as long as
    /// the playback controller exists, so we have to stop playback and let
    /// go of the controller explicitly — otherwise the chain stays running
    /// off-screen and audio continues playing after pop.
    func shutdown() {
        playerView.playbackController?.setVideos(nil)
        playerView.playbackController = nil
        viewModel.playbackController = nil
        viewModel.imaHost = nil
    }

    /// Called by `PlayerViewModel` on `didEnterAdSequence` in OMID mode.
    /// `playerView.overlayView` is the empty container above the ad — it
    /// does not paint pixels, so OMID can treat it as a `.notVisible`
    /// obstruction without affecting viewability measurement.
    func registerFriendlyObstruction(in adDisplayContainer: IMAAdDisplayContainer) {
        guard let overlay = playerView.overlayView else { return }
        let obstruction = IMAFriendlyObstruction(
            view: overlay,
            purpose: .notVisible,
            detailedReason: "Transparent overlay does not impact viewability"
        )
        adDisplayContainer.register(obstruction)
        Log.ads.info("Registered OMID friendly obstruction over player overlay")
    }

    private func makePlaybackController() -> BCOVPlaybackController? {
        guard let adContainer = playerView.contentOverlayView else { return nil }

        let imaSettings = IMASettings()
        imaSettings.language = Locale.current.language.languageCode?.identifier ?? "en"

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self
        renderSettings.linkOpenerDelegate = viewModel

        let companionSlot = IMACompanionAdSlot(
            view: viewModel.companionView,
            width: 300,
            height: 250
        )

        let sdkManager = BCOVPlayerSDKManager.sharedManager()

        // FairPlay session provider sits below IMA in the chain. Including
        // it even for unencrypted assets keeps the chain identical for
        // FairPlay content — the auth proxy is a no-op until a FairPlay
        // asset is loaded.
        let fpsAuthProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil, applicationId: nil)
        let fpsProvider = sdkManager.createFairPlaySessionProvider(
            withAuthorizationProxy: fpsAuthProxy,
            upstreamSessionProvider: nil
        )

        guard let imaProvider = sdkManager.createIMASessionProvider(
            with: imaSettings,
            adsRenderingSettings: renderSettings,
            adsRequestPolicy: adsRequestPolicy(for: viewModel.adMode),
            adContainer: adContainer,
            viewController: self,
            companionSlots: [companionSlot],
            upstreamSessionProvider: fpsProvider,
            options: [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: viewModel]
        ) else {
            return nil
        }

        return sdkManager.createPlaybackController(
            withSessionProvider: imaProvider,
            viewStrategy: nil
        )
    }

    private func adsRequestPolicy(for mode: AdMode) -> BCOVIMAAdsRequestPolicy {
        switch mode {
        case .vmap:
            // Reads the VMAP tag from the video's `kBCOVIMAAdTag` property.
            BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()
        case .vast, .vastOM:
            // Reads per-cuepoint VAST tags from the video's cuepoints. OMID
            // mode uses the same policy; what differs is the ad tag URL and
            // the friendly-obstruction registration on `didEnterAdSequence`.
            BCOVIMAAdsRequestPolicy(
                vastAdTagsInCuePointsAndAdsCuePointProgressPolicy: BCOVCuePointProgressPolicy(
                    processingCuePoints: .processFinalCuePoint,
                    resumingPlaybackFrom: .fromContentPlayhead,
                    ignoringPreviouslyProcessedCuePoints: false
                )
            )
        }
    }
}
