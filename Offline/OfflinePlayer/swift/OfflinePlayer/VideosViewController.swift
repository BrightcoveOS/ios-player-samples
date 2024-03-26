//
//  VideosViewController.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


final class VideosViewController: UIViewController {

    // View that holds the PlayerUI content
    // where the video and controls are displayed
    @IBOutlet fileprivate weak var videoContainerView: UIView!

    // Table view displaying available videos
    // from playlist, and its refresh control
    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            tableView.refreshControl = refreshControl
            tableView.contentInset = UIEdgeInsets(top: 0,
                                                  left: 0,
                                                  bottom: 0,
                                                  right: 0)
        }
    }

    @IBOutlet fileprivate weak var headerTableView: UIView! {
        didSet {
            headerTableView.layer.borderColor = UIColor.init(white: 0.9,
                                                             alpha: 1.0).cgColor
            headerTableView.layer.borderWidth = 0.3
            headerTableView.addSubview(headerLabel)
        }
    }

    @IBOutlet fileprivate weak var footerTableView: UIView! {
        didSet {
            footerTableView.layer.borderColor = UIColor.init(white: 0.9,
                                                             alpha: 1.0).cgColor
            footerTableView.layer.borderWidth = 0.3
            footerTableView.addSubview(footerLabel)
        }
    }

    fileprivate lazy var headerLabel: UILabel = {
        let headerLabel = UILabel(frame: CGRect(x: 20,
                                                y: 0,
                                                width: headerTableView.frame.size.width - 40,
                                                height: headerTableView.frame.size.height))
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .justified
        headerLabel.font = .boldSystemFont(ofSize: 16)
        headerLabel.textColor = .systemGray
        headerLabel.backgroundColor = .clear
        return headerLabel
    }()

    fileprivate lazy var footerLabel: UILabel = {
        let footerLabel = UILabel(frame: CGRect(x: 20,
                                                y: 0,
                                                width: footerTableView.frame.size.width - 40,
                                                height: footerTableView.frame.size.height))
        footerLabel.numberOfLines = 1
        footerLabel.textAlignment = .justified
        footerLabel.font = .boldSystemFont(ofSize: 14)
        footerLabel.textColor = .systemGray
        footerLabel.backgroundColor = .clear
        return footerLabel
    }()

    // Brightcove-related objects
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
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
                                                         applicationId: nil),
              let sourcePolicy = BCOVBasicSourceSelectionPolicy.sourceSelectionHLS(withScheme: kBCOVSourceURLSchemeHTTPS) else {
            return nil
        }

        // You can use the same auth proxy for the offline video manager
        // and the call to create the FairPlay session provider.
        offlineManager.authProxy = authProxy

        let bspOptions = BCOVBasicSessionProviderOptions()
        bspOptions.sourceSelectionPolicy = sourcePolicy

        guard let bsp = sdkManager.createBasicSessionProvider(with: bspOptions) else {
            return nil
        }

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: bsp)

        guard let playerView,
              let playbackController = sdkManager.createPlaybackController(with: fps,
                                                                           viewStrategy: nil) else {
            return nil
        }

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsBackgroundAudioPlayback = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(requestContentFromPlaybackService),
                                 for: .valueChanged)
        return refreshControl
    }()

    fileprivate lazy var statusBarHidden = false {
        didSet {
            if let tabBarController {
                tabBarController.tabBar.isHidden = statusBarHidden
            }

            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let options = [
            kBCOVOfflineVideoManagerAllowsCellularDownloadKey: false,
            kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: false,
            kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: false
        ]

        BCOVOfflineVideoManager.initializeOfflineVideoManager(with: DownloadManager.shared,
                                                              options: options)

        requestContentFromPlaybackService()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(analyticsStorageFullWarningNotificationReceived),
                                               name: NSNotification.Name.bcovOfflineVideoManagerAnalyticsStorageFullWarning,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateStatus(_:)),
                                               name: OfflinePlayerNotifications.UpdateStatus,
                                               object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: nil)
    }

    @objc
    fileprivate func analyticsStorageFullWarningNotificationReceived() {
        UIAlertController.showWith(title: "Analytics storage is full",
                                   message: "Encourage the app user to go online")
    }

    @objc
    fileprivate func updateStatus(_ notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            if isVisible {
                if let video = notification.object as? BCOVVideo,
                   let videoId = video.videoId,
                   let videoIndex = VideoManager.shared.videos.firstIndex(where: { $0.videoId == videoId }) {
                    let indexPath = IndexPath(row: videoIndex, section: 0)
                    tableView.reloadRows(at: [indexPath], with: .none)
                } else {
                    tableView.reloadData()
                }
            }

            if let tabBarController {
                tabBarController.updateBadge()
            }
        }
    }

    @objc
    fileprivate func requestContentFromPlaybackService() {
        refreshControl.beginRefreshing()

        let queryParams = ["limit": 100, "offset": 0]

        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetReferenceID: kPlaylistRefId]
        VideoManager.shared.retrievePlaylist(with: configuration,
                                             queryParameters: queryParams) {
            [self] (playlist: BCOVPlaylist?, json: [AnyHashable: Any]?, error: Error?) in

            refreshControl.endRefreshing()

            if let playlist,
               let videos = playlist.videos as? [BCOVVideo],
               let tabBarController,
               let settingsViewController = tabBarController.settingsViewController {

                let bitrate = settingsViewController.bitrate
                VideoManager.shared.usePlaylist(videos,
                                                with: bitrate)

                headerLabel.text = playlist.properties[kBCOVPlaylistPropertiesKeyName] as? String ?? "Offline Player"
                footerLabel.text = "\(videos.count) \(videos.count != 1 ? "Videos" : "Video")"
            } else {
                print("No playlist for Id \"\(kPlaylistRefId)\" was found.")

                headerLabel.text = "Offline Player"
                footerLabel.text = "0 Videos"
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension VideosViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")

        if let source = session.source {
            print("Session source details: \(source)")
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        guard let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError else {
            return
        }

        // Report any errors that may have occurred with playback.
        print("ViewController - Playback error: \(error.localizedDescription)")
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension VideosViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}


// MARK: - VideoTableViewCellDelegate

extension VideosViewController: VideoTableViewCellDelegate {

    func performDownload(forVideo video: BCOVVideo) {
        DownloadManager.shared.doDownload(forVideo: video)
    }
}


// MARK: - UITableViewDataSource

extension VideosViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return VideoManager.shared.videos.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let videoCell = tableView.dequeueReusableCell(withIdentifier: "VideoTableViewCell",
                                                            for: indexPath) as? VideoTableViewCell else {
            return UITableViewCell()
        }

        let video = VideoManager.shared.videos[indexPath.row]
        videoCell.setup(with: video,
                        and: self)

        return videoCell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}


// MARK: - UITableViewDelegate

extension VideosViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let video = VideoManager.shared.videos[indexPath.row]

        if let playbackController {
            if !(UIDevice.current.isSimulator && video.usesFairPlay) {
                playbackController.setVideos([video] as NSFastEnumeration)
            } else {
                UIAlertController.showWith(title: "FairPlay Warning",
                                           message: "FairPlay only works on actual iOS devices.\n\nYou will not be able to view any FairPlay content in the iOS simulator.")
            }
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}
