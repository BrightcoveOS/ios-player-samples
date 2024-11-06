//
//  ViewController.swift
//  ViewStrategy
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let viewStrategy: BCOVPlaybackControllerViewStrategy = {
            (videoView: UIView?,
             playbackController: BCOVPlaybackController?) -> UIView? in
            
            // Create some custom controls for the video view,
            // and compose both into a container view.
            guard let videoView,
                  let playbackController else {
                return nil
            }

            let controlsAndVideoView = UIView(frame: .zero)
            let controlsView = ViewStrategyCustomControls(with: playbackController)

            controlsAndVideoView.frame = videoView.bounds
            controlsAndVideoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            controlsView.frame = videoView.bounds
            controlsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            controlsAndVideoView.addSubview(videoView)
            controlsAndVideoView.addSubview(controlsView)

            playbackController.add(controlsView)

            return controlsAndVideoView
        }

        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps,
                                                                           viewStrategy: viewStrategy)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playbackController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playbackController.view.frame = videoContainerView.bounds
        videoContainerView.addSubview(playbackController.view)

        return playbackController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        requestContentFromPlaybackService()
    }
    
    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [playbackController] (video: BCOVVideo?,
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

            playbackController.setVideos([video])
        }
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
