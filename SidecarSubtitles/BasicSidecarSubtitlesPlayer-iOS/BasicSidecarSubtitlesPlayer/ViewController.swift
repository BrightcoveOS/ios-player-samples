//
//  ViewController.swift
//  BasicSidecarSubtitlesPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve a video from Video Cloud
 * and add a sidecar VTT captions file to it for playback.
 *
 * The interesting methods in the code are `-requestContentFromPlaybackService` and
 * `-textTracks`.
 *
 * `-requestContentFromPlaybackService` retrieves a video from Video Cloud
 * normally, but then it creates an array of text tracks, and adds them to the
 * BCOVVideo object. BCOVVideo is an immutable object, but you can create a new
 * modified copy of it by calling `BCOVVideo update:`.
 *
 * `-textTracks` creates the array of subtitle dictionaries.
 * When creating these dictionaries, be sure to make note of which fields
 * are required are optional as specified in BCOVSSComponent.h.
 *
 * Note that in this sample the subtitle track does not match the audio of the
 * video; it's only used as an example.
 *
 */

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
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView else {
            return nil
        }

        let sidecarSubtitlesSessionProvider = sdkManager.createSidecarSubtitlesSessionProvider(withUpstreamSessionProvider: fps)
        let playbackController = sdkManager.createPlaybackController(withSessionProvider: sidecarSubtitlesSessionProvider,
                                                                         viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var textTracks: [[String: Any]] = {
        // Create the array of subtitle dictionaries
        return [
            [
                // required tracks descriptor: BCOVSSConstants.TextTracksKindSubtitles or BCOVSSConstants.TextTracksKindCaptions
                BCOVSSConstants.TextTracksKeyKind: BCOVSSConstants.TextTracksKindSubtitles,

                // required language code
                BCOVSSConstants.TextTracksKeySourceLanguage: "en",

                // required display name
                BCOVSSConstants.TextTracksKeyLabel: "English",

                // required: source URL of WebVTT file or playlist as NSString
                BCOVSSConstants.TextTracksKeySource: "http://players.brightcove.net/3636334163001/ios_native_player_sdk/vtt/sample.vtt",

                // optional MIME type
                BCOVSSConstants.TextTracksKeyMIMEType: "text/vtt",

                // optional "default" indicator
                BCOVSSConstants.TextTracksKeyDefault: true,

                // duration is required for WebVTT URLs (ending in ".vtt")
                // optional for WebVTT playlists (ending in ".m3u8")
                BCOVSSConstants.TextTracksKeyDuration: NSNumber(value: 959), // seconds as NSNumber

                // The source type is only needed if your source URL
                // does not end in ".vtt" or ".m3u8" and thus its type is ambiguous.
                // Our URL ends in ".vtt" so we don't need to set this, but it won't hurt.
                BCOVSSConstants.TextTracksKeySourceType: BCOVSSConstants.TextTracksKeySourceTypeWebVTTURL
            ]
        ]
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

            let updatedVideo = video.update { [self] (mutableVideo: BCOVMutableVideo?) in

                // Get the existing text tracks, if any
                guard let properties = mutableVideo?.properties,
                      let currentTextTracks = properties[BCOVSSConstants.VideoPropertiesKeyTextTracks] as? [[String: Any]] else {
                    return
                }

                // Combine the two arrays together.
                // We don't want to lose the original tracks that might already be in there.
                let combinedTextTracks: [[String: Any]] = currentTextTracks + self.textTracks

                // Store text tracks in the text tracks property
                var updatedDictionary = properties
                updatedDictionary[BCOVSSConstants.VideoPropertiesKeyTextTracks] = combinedTextTracks
                mutableVideo?.properties = updatedDictionary
            }

            playbackController.setVideos([updatedVideo])
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
}
