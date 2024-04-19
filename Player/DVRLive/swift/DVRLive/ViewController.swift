//
//  ViewController.swift
//  DVRLive
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!

    fileprivate let kVideoURLString = "<URL of Live HLS>"
    
    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self

        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: .withLiveDVRLayout()) else {
            return nil
        }

        playerView.delegate = self

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)

        return playerView
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

        guard let playerView,
              let playbackController = sdkManager.createPlaybackController(with: fps,
                                                                           viewStrategy: nil) else {
            return nil
        }

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let playbackController,
              let videoURL = URL(string: kVideoURLString),
              let source = BCOVSource(url: videoURL,
                                      deliveryMethod: kBCOVSourceDeliveryHLS,
                                      properties: nil) else {
            return
        }

        let video = BCOVVideo(source: source, cuePoints: nil, properties: nil)

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

            DispatchQueue.main.async { [self] in
                present(alert, animated: true)
            }

            return
        }
#endif

        playbackController.setVideos([video] as NSFastEnumeration)
    }

}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}
