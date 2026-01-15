//
//  IMAPlayerController.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import BrightcoveIMA
import BrightcovePlayerSDK
import Foundation
import GoogleInteractiveMediaAds
import UIKit

/// IMA Player Controller that subclasses BCOVPUIPlayerViewController.
/// This ensures proper view controller hierarchy during fullscreen mode with IMA ads.
class IMAPlayerController: BCOVPUIPlayerViewController {

    let model: PlayerModel

    init(_ model: PlayerModel) {
        self.model = model

        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = true
        options.showPictureInPictureButton = true

        super.init(playbackController: nil, options: options, controlsView: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented;")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let playbackController = createIMAPlaybackController() else {
            return
        }

        playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: false]
        playbackController.delegate = model
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController
        playerView.delegate = model

        model.playbackController = playbackController
    }

    fileprivate func createIMAPlaybackController() -> BCOVPlaybackController? {
        guard let contentOverlayView = playerView.contentOverlayView else {
            return nil
        }

        let imaSettings = IMASettings()
        imaSettings.language = NSLocale.current.languageCode ?? "en"

        let renderSettings = IMAAdsRenderingSettings()
        renderSettings.linkOpenerPresentingController = self
        renderSettings.linkOpenerDelegate = model

        let policy = BCOVCuePointProgressPolicy.init(processingCuePoints: .processFinalCuePoint,
                                                     resumingPlaybackFrom: .fromContentPlayhead,
                                                     ignoringPreviouslyProcessedCuePoints: false)

        let adsRequestPolicy = BCOVIMAAdsRequestPolicy.init(vastAdTagsInCuePointsAndAdsCuePointProgressPolicy: policy)

        let imaPlaybackSessionOptions = [kBCOVIMAOptionIMAPlaybackSessionDelegateKey: model]

        let sdkManager = BCOVPlayerSDKManager.sharedManager()

        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                                   authorizationProxy: authProxy,
                                                                   upstreamSessionProvider: nil)

        guard let imaSessionProvider = sdkManager.createIMASessionProvider(with: imaSettings,
                                                                           adsRenderingSettings: renderSettings,
                                                                           adsRequestPolicy: adsRequestPolicy,
                                                                           adContainer: contentOverlayView,
                                                                           viewController: self,
                                                                           companionSlots: nil,
                                                                           upstreamSessionProvider: fps,
                                                                           options: imaPlaybackSessionOptions) else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: imaSessionProvider,
                                                                     viewStrategy: nil)

        return playbackController
    }
}
