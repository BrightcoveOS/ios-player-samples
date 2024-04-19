//
//  ViewController.swift
//  SubtitleRendering
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
    @IBOutlet fileprivate weak var subtitlesLabel: UILabel! {
        didSet {
            subtitlesLabel.text = nil
        }
    }

    @IBOutlet fileprivate weak var tableView: UITableView!
    
    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self

        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: .withVODLayout()) else {
            return nil
        }

        // Hide built-in CC button
        if let ccButton = playerView.controlsView.closedCaptionButton {
            ccButton.isHidden = true
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

    fileprivate lazy var textTracks: [[String: Any]]? = .init()
    fileprivate var subtitleManager: SubtitleManager?

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
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                                  jsonResponse: [AnyHashable: Any]?,
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

            gatherUsableTextTracks(video)
        }
    }

    fileprivate func gatherUsableTextTracks(_ video: BCOVVideo) {
        // We need to get an array of available text tracks
        // for this video. In this case we are going to use the
        // `text_tracks` array on this video's properties dictionary.
        // We're also going to set the `default` value of any of these
        // text tracks to ensure that AVPlayer doesn't select a track
        // automatically and attempt to render it itself.
        
        guard let allTextTracks = video.properties["text_tracks"] as? [[String: Any]] else {
            return
        }

        textTracks = allTextTracks
            .filter { $0["kind"] as? String == "captions" || $0["kind"] as? String == "subtitles" }
            .enumerated().map { idx, element in
                var textTrack = element
                textTrack["default"] = false
                return textTrack
            }

        tableView.reloadData()
        
        // If we have text tracks go ahead and
        // select the first one
        if let textTracks,
           let firstTextTrack = textTracks.first {
            useTextTrack(firstTextTrack)
        }
        
        // Now update the BCOVVideo with our new text tracks array
        let updatedVideo = video.update { [self] (mutableVideo: BCOVMutableVideo) in
            if let textTracks,
               var props = mutableVideo.properties {
                props["text_tracks"] = textTracks
                mutableVideo.properties = props
            }
        }

        if let playbackController {
            playbackController.setVideos([updatedVideo] as NSFastEnumeration)
        }
    }
    
    fileprivate func useTextTrack(_ textTrack: [String: Any]) {
        // Look for an HTTPS source
        guard let sources = textTrack["sources"] as? [[String: Any]] else {
            return
        }
        
        var httpsSource: String?
        
        for srcDict in sources {
            if let src = srcDict["src"] as? String {
                if src.hasPrefix("https://") {
                    httpsSource = src
                    break
                }
            }
        }
        
        // If no HTTPS src is found fallback to default src
        let src = httpsSource ?? (textTrack["src"] as? String ?? "")
        
        guard let subtitleURL = URL(string: src) else {
            print("Couldn't create URL from text track src")
            return
        }

        subtitleManager = SubtitleManager(subtitleURL: subtitleURL)
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")

        if (UIAccessibility.isClosedCaptioningEnabled) {
            print("WARNING: Closed Captions + SDH is enabled in the device Accessibility settings.")
            print("         A text track might be forcibly rendered in the video view.")
        }

        session.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60),
                                               queue: DispatchQueue.main) {
            [self] (time: CMTime) in

            if let subtitle = subtitleManager?.subtitleForTime(time) {
                subtitlesLabel.text = subtitle
            }
        }
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


// MARK: UITableViewDelegate

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, 
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            if let textTrack = textTracks?[indexPath.row] {
                useTextTrack(textTrack)
            }
        } else {
            subtitleManager = nil
            subtitlesLabel.text = nil
        }
    }
}

// MARK: UITableViewDataSource

extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? textTracks?.count ?? 0 : 1
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Text Tracks" : nil
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TextTrackCell") else {
            return UITableViewCell()
        }

        if indexPath.section == 0 {
            if let textTrack = textTracks?[indexPath.row],
               let label = textTrack["label"] as? String,
               let srclang = textTrack["srclang"] as? String {
                cell.textLabel?.text = "\(label) (\(srclang))"
            }
        } else {
            cell.textLabel?.text = "Disable text track"
        }

        return cell
    }
}
