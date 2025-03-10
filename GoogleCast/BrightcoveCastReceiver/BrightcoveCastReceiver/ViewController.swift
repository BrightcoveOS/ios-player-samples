//
//  ViewController.swift
//  BrightcoveCastReceiver
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleCast
import BrightcovePlayerSDK
import BrightcoveGoogleCast


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kPlaylistRefId = "brightcove-native-sdk-plist"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView! {
        didSet {
            let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0,
                                                           width: 24, height: 24))
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)

            videoContainerView.isHidden = true
        }
    }

    @IBOutlet fileprivate weak var headerTableView: UIView! {
        didSet {
            headerTableView.backgroundColor = .systemGroupedBackground
            headerTableView.layer.borderColor = UIColor.init(white: 0.9,
                                                             alpha: 1.0).cgColor
            headerTableView.layer.borderWidth = 0.3
            headerTableView.addSubview(headerLabel)
        }
    }

    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            tableView.contentInset = UIEdgeInsets(top: 0,
                                                  left: 0,
                                                  bottom: 0,
                                                  right: 0)
        }
    }

    fileprivate lazy var headerLabel: UILabel = {
        let size = headerTableView.frame.size
        let headerLabel = UILabel(frame: CGRect(x: 20,
                                                y: 0,
                                                width: size.width - 40,
                                                height: size.height))
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .justified
        headerLabel.font = .boldSystemFont(ofSize: 16)
        headerLabel.textColor = .systemGray
        return headerLabel
    }()

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            options.presentingViewController = appDelegate.castContainerViewController
        } else {
            options.presentingViewController = self
        }

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

    fileprivate(set) lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps, viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsBackgroundAudioPlayback = true

        playerView.playbackController = playbackController

        googleCastManager.delegate = self

        playbackController.add(googleCastManager)

        return playbackController
    }()

    fileprivate var googleCastManager: BCOVGoogleCastManager  = {
        let receiverAppConfig = BCOVReceiverAppConfig()
        receiverAppConfig.accountId = kAccountId
        receiverAppConfig.policyKey = kPolicyKey
        receiverAppConfig.splashScreen = "https://solutions.brightcove.com/jblaker/cast-splash.jpg"

        // You can specify a customized player
        // receiverAppConfig.playerUrl = "https://players.brightcove.net/5434391461001/nVM2434Z1_default/index.min.js"

        // You can use the authToken property for PAS/EPA
        // receiverAppConfig.authToken = ""

        // You can use the adConfigId property for SSAI
        // Intended to be used alongside the SSAI Plugin for Brightcove Player SDK for iOS
        // receiverAppConfig.adConfigId = ""

        return BCOVGoogleCastManager(forBrightcoveReceiverApp: receiverAppConfig)
    }()

    fileprivate lazy var videos: [BCOVVideo] = .init()

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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(castStateDidChange),
                                               name: NSNotification.Name.gckCastStateDidChange,
                                               object: GCKCastContext.sharedInstance())
    }

    @objc
    fileprivate func castStateDidChange(_ notification: Notification) {
        let state = GCKCastContext.sharedInstance().castState

        switch state {
            case .noDevicesAvailable:
                print("No cast devices available")
            case .connected:
                print("Cast device connected")
            case .connecting:
                print("Cast device connecting")
            case .notConnected:
                print("Cast device not connected")
            default:
                print("Unknown Cast State Change")
        }
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetReferenceID: kPlaylistRefId]
        let queryParams = ["limit": 100, "offset": 0]

        playbackService.findPlaylist(withConfiguration: configuration,
                                     queryParameters: queryParams) {
            [self] (playlist: BCOVPlaylist?,
                    json: Any?,
                    error: Error?) in

            if let playlist {
                let videos = playlist.videos
                headerLabel.text = playlist.properties[BCOVPlaylist.PropertiesKeyName] as? String ?? "BrightcoveCastReceiver"
#if targetEnvironment(simulator)
                self.videos = videos.filter({ !$0.usesFairPlay })
#else
                self.videos = videos
#endif
                tableView.reloadData()
            } else {
                headerLabel.text = "BrightcoveCastReceiver"
                print("No playlist for Id \"\(kPlaylistRefId)\" was found.")
            }
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
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventEnd == lifecycleEvent.eventType {
            videoContainerView.isHidden = true
        }

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


// MARK: - BCOVGoogleCastManager

extension ViewController: BCOVGoogleCastManagerDelegate {

    func switched(toLocalPlayback lastKnownStreamPosition: TimeInterval,
                  withError error: Error?) {

        if lastKnownStreamPosition > 0,
           let playbackController {
            playbackController.play()
        }

        videoContainerView.isHidden = false

        if let error {
            print("Switched to local playback with error: \(error.localizedDescription)")
        }
    }

    func switchedToRemotePlayback() {
        videoContainerView.isHidden = true
    }

    func currentCastedVideoDidComplete() {
        videoContainerView.isHidden = true
    }

    func castedVideoFailedToPlay() {
        print("Failed to play Cast video")
    }

    func suitableSourceNotFound() {
        print("Suitable source for video not found!")
    }
}


// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : videos.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let videoCell = tableView.dequeueReusableCell(withIdentifier: "BasicCell",
                                                      for: indexPath)
        if indexPath.section == 0 {
            videoCell.textLabel?.text = "Play All"
            return videoCell
        }

        let video = videos[indexPath.row]

        if let name = video.properties[BCOVVideo.PropertyKeyName] as? String {
            videoCell.textLabel?.text = name
        }

        return videoCell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return videos.count > 0 ? 2 : 0
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
}


// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        videoContainerView.isHidden = GCKCastContext.sharedInstance().castState == .connected

        guard let playbackController else { return }

        if indexPath.section == 0 {
            playbackController.setVideos(videos)
            return
        }

        let video = videos[indexPath.row]
        playbackController.setVideos([video])
    }
}
