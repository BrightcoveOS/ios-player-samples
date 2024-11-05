//
//  ViewController.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "5702141808001"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps, viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsExternalPlayback = true
        playbackController.add(controlsViewController)

        playbackController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        controlsViewController.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var videoView: UIView = {
        let videoView = UIView()
        videoView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return videoView
    }()

    fileprivate lazy var controlsViewController: ControlsViewController = {
        let controlsViewController = ControlsViewController()
        controlsViewController.delegate = self
        return controlsViewController
    }()

    fileprivate lazy var fullscreenViewController: UIViewController = UIViewController()

    fileprivate lazy var standardVideoViewConstraints: [NSLayoutConstraint] = {
        return [
            videoView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            videoView.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
            videoView.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
            videoView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
        ]
    }()

    fileprivate lazy var fullscreenVideoViewConstraints: [NSLayoutConstraint] = {
        var insets = view.safeAreaInsets
        return [
            videoView.topAnchor.constraint(equalTo: fullscreenViewController.view.topAnchor, constant:insets.top),
            videoView.rightAnchor.constraint(equalTo: fullscreenViewController.view.rightAnchor),
            videoView.leftAnchor.constraint(equalTo: fullscreenViewController.view.leftAnchor),
            videoView.bottomAnchor.constraint(equalTo: fullscreenViewController.view.bottomAnchor, constant:-insets.bottom)
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the playbackController view
        // to videoView and setup its constraints
        videoView.addSubview(playbackController.view)
        playbackController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playbackController.view.topAnchor.constraint(equalTo: videoView.topAnchor),
            playbackController.view.rightAnchor.constraint(equalTo: videoView.rightAnchor),
            playbackController.view.leftAnchor.constraint(equalTo: videoView.leftAnchor),
            playbackController.view.bottomAnchor.constraint(equalTo: videoView.bottomAnchor)
        ])

        // Setup controlsViewController by
        // adding it as a child view controller,
        // adding its view as a subview of videoView
        // and adding its constraints
        addChild(controlsViewController)
        videoView.addSubview(controlsViewController.view)
        controlsViewController.didMove(toParent: self)
        controlsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controlsViewController.view.topAnchor.constraint(equalTo: videoView.topAnchor),
            controlsViewController.view.rightAnchor.constraint(equalTo: videoView.rightAnchor),
            controlsViewController.view.leftAnchor.constraint(equalTo: videoView.leftAnchor),
            controlsViewController.view.bottomAnchor.constraint(equalTo: videoView.bottomAnchor)
        ])

        // Then add videoView as a subview of videoContainer
        videoContainerView.addSubview(videoView)

        // Activate the standard view constraints
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(standardVideoViewConstraints)

        requestContentFromPlaybackService()
    }

    // MARK: - Misc

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [playbackController] (video: BCOVVideo?,
                                  jsonResponse: Any?,
                                  error: Error?) in
            guard let video else {
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


// MARK: - ControlsViewControllerFullScreenDelegate

extension ViewController: ControlsViewControllerFullScreenDelegate {

    func handleEnterFullScreenButtonPressed() {
        fullscreenViewController.addChild(controlsViewController)
        fullscreenViewController.view.addSubview(videoView)
        NSLayoutConstraint.deactivate(standardVideoViewConstraints)
        NSLayoutConstraint.activate(fullscreenVideoViewConstraints)
        controlsViewController.didMove(toParent: fullscreenViewController)

        present(fullscreenViewController, animated: false, completion: nil)
    }

    func handleExitFullScreenButtonPressed() {
        dismiss(animated: false) { [self] in
            addChild(controlsViewController)
            videoContainerView.addSubview(videoView)
            NSLayoutConstraint.deactivate(fullscreenVideoViewConstraints)
            NSLayoutConstraint.activate(standardVideoViewConstraints)
            controlsViewController.didMove(toParent: self)
        }
    }
}
