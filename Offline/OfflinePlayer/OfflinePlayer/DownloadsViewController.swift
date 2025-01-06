//
//  DownloadsViewController.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


// The Downloads View Controller displays a list of HLS videos that have been
// downloaded, including videos that are "preloaded", meaning their FairPlay
// licenses have been acquired, and the video content is yet to be downloaded.
//
// You can tap on a video to select it, and thus display information about it.
//
// After selecting it, tap "play" to play the video.
//
// Slide to delete a video.
//
// Tap "More…" to log information about the current video, renew the FairPlay
// license, or delete the video.


final class DownloadsViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView! {
        didSet {
            videoContainerView.isHidden = true
        }
    }

    @IBOutlet fileprivate weak var posterImageView: UIImageView! {
        didSet {
            posterImageView.contentMode = .scaleAspectFill
            posterImageView.clipsToBounds = true
        }
    }

    @IBOutlet fileprivate weak var infoLabel: UILabel! {
        didSet {
            infoLabel.isHidden = true
            infoLabel.numberOfLines = 10
        }
    }

    @IBOutlet fileprivate weak var noVideoSelectedLabel: UILabel!

    @IBOutlet fileprivate weak var playButton: UIButton! {
        didSet {
            playButton.isHidden = true
        }
    }

    @IBOutlet
    fileprivate weak var moreButton: UIButton! {
        didSet {
            moreButton.isHidden = true
        }
    }

    @IBOutlet fileprivate weak var taskLabel: UILabel! {
        didSet {
            taskLabel.isHidden = true
        }
    }

    @IBOutlet fileprivate weak var pauseButton: UIButton! {
        didSet {
            pauseButton.isHidden = true
        }
    }

    @IBOutlet fileprivate weak var cancelButton: UIButton! {
        didSet {
            cancelButton.isHidden = true
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

    @IBOutlet fileprivate weak var headerTableView: UIView! {
        didSet {
            headerTableView.layer.borderColor = UIColor.init(white: 0.9,
                                                             alpha: 1.0).cgColor
            headerTableView.layer.borderWidth = 0.3
            headerTableView.addSubview(headerLabel)
        }
    }

    @IBOutlet  fileprivate weak var footerTableView: UIView! {
        didSet {
            footerTableView.layer.borderColor = UIColor.init(white: 0.9,
                                                             alpha: 1.0).cgColor
            footerTableView.layer.borderWidth = 0.3
            footerTableView.addSubview(downloadVideosLabel)
            footerTableView.addSubview(freeSpaceLabel)
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

    fileprivate lazy var downloadVideosLabel: UILabel = {
        let downloadVideos = UILabel(frame: CGRect(x: 20,
                                                   y: 0,
                                                   width: footerTableView.frame.size.width - 40,
                                                   height: 28))
        downloadVideos.numberOfLines = 1
        downloadVideos.textAlignment = .justified
        downloadVideos.font = .boldSystemFont(ofSize: 14)
        downloadVideos.textColor = .systemGray
        downloadVideos.backgroundColor = .clear
        return downloadVideos
    }()

    fileprivate lazy var freeSpaceLabel: UILabel = {
        let freeSpaceLabel = UILabel(frame: CGRect(x: 0,
                                                   y: 28,
                                                   width: footerTableView.frame.size.width,
                                                   height: 28))
        freeSpaceLabel.numberOfLines = 1
        freeSpaceLabel.textAlignment = .center
        freeSpaceLabel.font = .boldSystemFont(ofSize: 14)
        freeSpaceLabel.backgroundColor = .init(white: 0.9,
                                               alpha: 1.0)
        return freeSpaceLabel
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
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        guard let offlineManager = BCOVOfflineVideoManager.shared() else {
            return nil
        }
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                   applicationId: nil)
        let sourcePolicy = BCOVBasicSourceSelectionPolicy.sourceSelectionHLS(withScheme: BCOVSource.URLSchemeHTTPS)

        let bspOptions = BCOVBasicSessionProviderOptions()
        bspOptions.sourceSelectionPolicy = sourcePolicy

        let bsp = sdkManager.createBasicSessionProvider(withOptions: bspOptions)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: bsp)

        guard let playerView else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps, viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsBackgroundAudioPlayback = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    // The offline video token of the video selected in the table
    fileprivate lazy var selectedOfflineVideoToken: String? = nil {
        didSet {
            resetVideoContainer()

            updateInfoForSelectedDownload()

            updateButtonTitles()
        }
    }

    // The offline video token playing in the video view
    fileprivate lazy var currentlyPlayingOfflineVideoToken: String? = .init()

    fileprivate var freeSpaceTimer: Timer?

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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateStatus(_:)),
                                               name: OfflinePlayerNotifications.UpdateStatus,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        freeSpaceTimer = Timer.scheduledTimer(timeInterval: 3.0,
                                              target: self,
                                              selector: #selector(updateFreeSpaceLabel),
                                              userInfo: nil,
                                              repeats: true)

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        freeSpaceTimer?.invalidate()
        freeSpaceTimer = nil
    }

    @objc
    fileprivate func updateStatus(_ notification: NSNotification) {
        guard isVisible,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatusArray = offlineManager.offlineVideoStatus(),
              let offlineVideoTokens = offlineManager.offlineVideoTokens else {
            tableView.reloadData()
            return
        }

        DispatchQueue.main.async { [self] in
            if let video = notification.object as? BCOVVideo,
               let offlineVideoToken = video.offlineVideoToken,
               let offlineVideoTokenIndex = offlineVideoTokens.firstIndex(where: { $0 == offlineVideoToken }) {
                let indexPath = IndexPath(row: offlineVideoTokenIndex, section: 0)
                tableView.reloadRows(at: [indexPath], with: .none)
                updateButtonTitles()
                updateInfoForSelectedDownload()
            } else {
                tableView.reloadData()
            }

            let inProgressCount = offlineVideoStatusArray.filter({ $0.downloadState == .stateDownloading }).count

            switch inProgressCount {
                case 0:
                    downloadVideosLabel.text = "No Videos Downloading"
                case 1:
                    downloadVideosLabel.text = "1 Video is still Downloading"
                default:
                    downloadVideosLabel.text = "\(inProgressCount) Videos are still Downloading"
            }

            headerLabel.text = "\(offlineVideoTokens.count) Offline \(offlineVideoTokens.count != 1 ? "Videos" : "Video")"

            updateFreeSpaceLabel()
        }
    }

    @objc
    fileprivate func updateFreeSpaceLabel() {
        if let freeDiskSpace = Double(UIDevice.current.freeDiskSpace) {
            if freeDiskSpace < 50 {
                freeSpaceLabel.textColor = .systemOrange
            } else if freeDiskSpace < 10 {
                freeSpaceLabel.textColor = .systemRed
            } else {
                freeSpaceLabel.textColor = .systemGray
            }
        }

        freeSpaceLabel.text = "Free: \(UIDevice.current.freeDiskSpace) GB of \(UIDevice.current.totalDiskSpace) GB"
    }

    fileprivate func resetVideoContainer() {
        videoContainerView.isHidden = true

        if let playbackController {
            playbackController.pause()
            playbackController.setVideos(nil)
        }

        currentlyPlayingOfflineVideoToken = nil
    }

    fileprivate func updateInfoForSelectedDownload() {
        noVideoSelectedLabel.isHidden = selectedOfflineVideoToken != nil
        posterImageView.isHidden = selectedOfflineVideoToken == nil
        infoLabel.isHidden = selectedOfflineVideoToken == nil

        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: selectedOfflineVideoToken),
              let video = offlineManager.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken) else {
            return
        }

        // Load poster image into the detail view
        if let posterPathString = video.properties[BCOVOfflineVideo.PosterFilePathPropertyKey] as? String,
           let posterImage = UIImage(contentsOfFile: posterPathString) {
            posterImageView.backgroundColor = .clear
            posterImageView.image = posterImage
        } else {
            posterImageView.backgroundColor = .black
            posterImageView.image = UIImage(named: "AppIcon")
        }

        infoLabel.text = "\(video.localizedName ?? "unknown")\nLicense: \(video.license)\nStatus: \(offlineVideoStatus.infoForDonwloadState)"
        infoLabel.sizeToFit()
    }

    fileprivate func updateButtonTitles() {
        guard let selectedOfflineVideoToken,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let status = offlineManager.offlineVideoStatus(forToken: selectedOfflineVideoToken) else {
            playButton.isHidden = true
            moreButton.isHidden = true
            taskLabel.isHidden = true
            pauseButton.isHidden = true
            cancelButton.isHidden = true
            return
        }

        let showTaskButtons = ![BCOVOfflineVideoDownloadState.stateDownloading,
                                BCOVOfflineVideoDownloadState.stateSuspended].contains(status.downloadState)

        playButton.isHidden = false
        moreButton.isHidden = false
        taskLabel.isHidden = showTaskButtons
        pauseButton.isHidden = showTaskButtons
        cancelButton.isHidden = showTaskButtons

        playButton.setTitle("Play", for: .normal)

        switch status.downloadState {
            case .stateDownloading:
                pauseButton.setTitle("Pause", for: .normal)
            case .stateSuspended:
                pauseButton.setTitle("Resume", for: .normal)
            default:
                break
        }
    }

    fileprivate func deleteVideo(for offlineVideoToken: String) {
        guard let offlineManager = BCOVOfflineVideoManager.shared() else { return }

        offlineManager.deleteOfflineVideo(offlineVideoToken)

        if offlineVideoToken == selectedOfflineVideoToken ||
            offlineVideoToken == currentlyPlayingOfflineVideoToken ||
            offlineManager.offlineVideoTokens.count == 0 {
            selectedOfflineVideoToken = nil
        }

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: nil)
    }

    fileprivate func renewLicense(for offlineVideoToken: String) {
        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: offlineVideoToken) else {
            return
        }

        // Get updated video object to pass to renewal method
        VideoManager.shared.retrieveVideo(offlineVideo) {
            (video: BCOVVideo?, jsonResponse: [AnyHashable : Any]?, error: Error?) in

            if let error {
                print("Could not retrieve new video during FairPlay license renewal. Error: \(error.localizedDescription)")
            }

            if let video {
                let licenseParamaters = DownloadManager.licenseParameters

                offlineManager.renewFairPlayLicense(offlineVideoToken,
                                                    video: video,
                                                    parameters: licenseParamaters) {
                    (offlineVideoToken: String?, error: Error?) in

                    if let error {
                        print("FairPlay license renewal completed with error: \(error.localizedDescription)")
                    }

                    if let offlineVideoToken {
                        let updatedVideo = video.update { (mutableVideo: BCOVMutableVideo) in
                            var mutableProperties = mutableVideo.properties
                            mutableProperties[BCOVOfflineVideo.TokenPropertyKey] = offlineVideoToken
                            mutableVideo.properties = mutableProperties
                        }

                        DispatchQueue.main.async {
                            // Show the new license
                            NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                                            object: updatedVideo)
                        }
                    }
                }
            }
        }
    }

    fileprivate func confirmDeletion(for video: BCOVVideo) {
        let alert = UIAlertController(title: "Delete Offline Video",
                                      message: "Are you sure you want to delete the offline video \"\(video.localizedName ?? "unknown")\"",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel))

        alert.addAction(UIAlertAction(title: "Delete Offline Video",
                                      style: .destructive) {
            [self] (action: UIAlertAction) in
            guard let offlineVideoToken = video.offlineVideoToken else { return }

            deleteVideo(for: offlineVideoToken)
        })

        present(alert, animated: true)
    }

    fileprivate func cancelVideoDownload() {
        guard let selectedOfflineVideoToken,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: selectedOfflineVideoToken) else {
            return
        }

        switch offlineVideoStatus.downloadState {
            case .stateRequested,
                    .stateDownloading,
                    .stateSuspended:
                offlineManager.cancelVideoDownload(selectedOfflineVideoToken)
            default:
                break
        }
    }

    fileprivate func logStatus() {
        // Log a variety of information to the debug console
        // about the currently selected offline video token.
        guard let selectedOfflineVideoToken,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken) else {
            print("Token unavailable or video not found")
            return
        }

        print("Video Properties: \(offlineVideo.properties)")
    }

    @IBAction
    fileprivate func doPlayHideButton(_ sender: UIButton) {
        guard let playbackController,
              let selectedOfflineVideoToken,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: selectedOfflineVideoToken),
              let titleLabel = sender.titleLabel else {
            return
        }

        if selectedOfflineVideoToken != currentlyPlayingOfflineVideoToken {
            // iOS 13 returns an incorrect value for `playableOffline`
            // if the offline video is already loaded into an
            // AVPlayer instance. Clearing out the current AVPlayer
            // instance solves the issue.
            playbackController.setVideos(nil)

            if offlineVideoStatus.downloadState == .stateCancelled {
                UIAlertController.showWith(title: "",
                                           message: "This video is not currently playable. The download was cancelled.")
                return
            }

            if !offlineVideoStatus.offlineVideo.playableOffline {
                UIAlertController.showWith(title: "",
                                           message: "This video is not currently playable. The download may still be in progress.")
                return
            }

            playbackController.setVideos([offlineVideoStatus.offlineVideo])
            currentlyPlayingOfflineVideoToken = selectedOfflineVideoToken

        }

        playButton.setTitle(titleLabel.text == "Play" ? "Hide" : "Play",
                            for: .normal)
        posterImageView.isHidden = !posterImageView.isHidden
        infoLabel.isHidden = !infoLabel.isHidden
        videoContainerView.isHidden = !videoContainerView.isHidden
    }


    @IBAction
    fileprivate func doMoreButton(_ sender: UIButton) {
        guard let selectedOfflineVideoToken,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken) else {
            return
        }

        let message = "Additional options for offline video \"\(offlineVideo.localizedName ?? "unknown")\""
        let alert = UIAlertController(title: "More Options",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Log Status",
                                      style: .default) {
            [self] (action: UIAlertAction) in
            logStatus()
        })

        if offlineVideo.usesFairPlay {
            alert.addAction(UIAlertAction(title: "Renew License",
                                          style: .default) {
                [self] (action: UIAlertAction) in
                renewLicense(for: selectedOfflineVideoToken)
            })
        }

        alert.addAction(UIAlertAction(title: "Delete Offline Video",
                                      style: .default) {
            [self] (action: UIAlertAction) in
            confirmDeletion(for: offlineVideo)
        })

        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel))

        present(alert, animated: true)
    }

    @IBAction
    fileprivate func doPauseResumeButton(_ sender: UIButton) {
        // Pause or resume based on the current state of the download
        guard let selectedOfflineVideoToken,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: selectedOfflineVideoToken) else {
            return
        }

        switch offlineVideoStatus.downloadState {
            case .stateDownloading:
                offlineManager.pauseVideoDownload(selectedOfflineVideoToken)
            case .stateSuspended:
                offlineManager.resumeVideoDownload(selectedOfflineVideoToken)
            default:
                break
        }

        // Disable pause button for a moment to prevent button spamming
        pauseButton?.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 1,
                             repeats: false) { [self] _ in
            pauseButton?.isEnabled = true
        }

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: offlineVideoStatus.offlineVideo)
    }

    @IBAction
    fileprivate func doCancelButton(_ sender: UIButton) {
        cancelVideoDownload()
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension DownloadsViewController: BCOVPlaybackControllerDelegate {

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

        print("Error: \(error.localizedDescription)")

        if error.code == BCOVOfflineVideoManagerErrorCode.ExpiredLicense.rawValue {
            UIAlertController.showWith(title: "License Expired",
                                       message: "The FairPlay license for the video \"\(session.video.localizedName ?? "unknown")\" has expired")

            selectedOfflineVideoToken = session.video.offlineVideoToken
        }
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension DownloadsViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}


// MARK: - UITableViewDataSource

extension DownloadsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoTokens = offlineManager.offlineVideoTokens else {
            return 0
        }

        return offlineVideoTokens.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let videoCell = tableView.dequeueReusableCell(withIdentifier: "VideoTableViewCell",
                                                            for: indexPath) as? VideoTableViewCell,
              let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoTokens = offlineManager.offlineVideoTokens else {
            return UITableViewCell()
        }

        let offlineVideoToken = offlineVideoTokens[indexPath.row]
        let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: offlineVideoToken)

        videoCell.setup(with: offlineVideo)

        return videoCell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool {
        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let sofflineVideoStatusArray = offlineManager.offlineVideoStatus() else {
            return false
        }

        let offlineVideoStatus = sofflineVideoStatusArray[indexPath.row]

        return offlineVideoStatus.downloadState != .stateDownloading
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoTokens = offlineManager.offlineVideoTokens else {
            return
        }

        let offlineVideoToken = offlineVideoTokens[indexPath.row]

        deleteVideo(for: offlineVideoToken)
    }
}


// MARK: - UITableViewDelegate

extension DownloadsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoTokens = offlineManager.offlineVideoTokens else {
            return
        }

        selectedOfflineVideoToken = offlineVideoTokens[indexPath.row]
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}
