//
//  ViewController.swift
//  Video360Player
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve and play a 360 video.
 * The code for retrieving and playing the video is identical
 * to any other code that retrieves and plays a video from Video Cloud.
 *
 * What makes this code different is the usage of the
 * BCOVPUIPlayerViewDelegate delegate method
 * `-didSetVideo360NavigationMethod:projectionStyle:`
 * This method is called when the Video 360 button is tapped, and indicates that
 * you probably want to set the device orientation to landscape if the
 * projection method has changed to VR Goggles mode.
 *
 * The code below shows how to handle changing the device orientation
 * when that delegate is called.
 */

import UIKit
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "1685628526640737870"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true

        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: nil) else {
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return landscapeOnly ? .landscape : .all
    }

    override var shouldAutorotate: Bool {
        return true
    }

    fileprivate lazy var landscapeOnly = false

    override func viewDidLoad() {
        super.viewDidLoad()

        requestContentFromPlaybackService()
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [playbackController] (video: BCOVVideo?,
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

            // Check "projection" property to confirm that this is a 360 degree video
            if let projectionProperty = video.properties[kBCOVVideoPropertyKeyProjection] as? String,
               projectionProperty == "equirectangular" {
                print("Retrieved a 360 video")
            }

            playbackController.setVideos([video] as NSFastEnumeration)
        }
    }

    fileprivate func handleOrientationForStandard() {
        // Switch orientation
        UIDevice.current.setValue(NSNumber(value: UIInterfaceOrientation.portrait.rawValue),
                                  forKey: "orientation")

        UIViewController.attemptRotationToDeviceOrientation()

        guard let playerView else { return }
        playerView.performScreenTransition(with: .normal)
    }

    fileprivate func handleOrientationForGoggles() {
        switch UIDevice.current.orientation {
            case .landscapeLeft,
                    .landscapeRight:
                // Already landscape
                break

            default:
                // Switch orientation
                UIDevice.current.setValue(NSNumber(value: UIInterfaceOrientation.landscapeLeft.rawValue),
                                          forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
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


// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }

    func didSetVideo360NavigationMethod(_ navigationMethod: BCOVPUIVideo360NavigationMethod,
                                        projectionStyle: BCOVVideo360ProjectionStyle) {
        // This method is called when the Video 360 button is tapped.
        // Use this notification to force an orientation change for the VR Goggles projection style.

        switch projectionStyle {
            case .normal:
                print("projectionStyle == BCOVVideo360ProjectionStyleNormal")

                // No landscape restriction
                landscapeOnly = false

                // If the goggles are off, change the device orientation
                // and exit full-screen
                handleOrientationForStandard()

            case .vrGoggles:
                print("projectionStyle == BCOVVideo360ProjectionStyleVRGoggles")

                // Allow only landscape if wearing goggles
                landscapeOnly = true

                // If the goggles are on, change the device orientation
                handleOrientationForGoggles()

            default:
                break
        }
    }
}
