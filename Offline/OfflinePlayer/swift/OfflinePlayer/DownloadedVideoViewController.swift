//
//  DownloadedVideoViewController.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
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
// Long-press on a video to download its secondary audio tracks (iOS 11+)
//
// Slide to delete a video.
//
// Tap "More…" to log information about the current video, renew the FairPlay
// license, or delete the video.

class DownloadedVideoViewController: BaseVideoViewController {
    
    @IBOutlet weak var downloadProgressView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton! {
        didSet {
            pauseButton.setTitle("--", for: .normal)
        }
    }
    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.setTitle("--", for: .normal)
        }
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var freeSpaceLabel: UILabel!
    
    private var selectedOfflineVideoToken: String?
    private var currentlyPlayingOfflineVideoToken: String?
    private var freeSpaceTimer: Timer?
    private var sessionStartTime: Date?
    
    private lazy var dataSource: DownloadsTableDataSource = {
        return DownloadsTableDataSource(tableView: tableView)
    }()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoContainerView.alpha = 0.0
        tableView.dataSource = dataSource
        updateInfoForSelectedDownload()
        setupLongPressGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateFreeSpaceLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        freeSpaceTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateFreeSpaceLabel), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        freeSpaceTimer?.invalidate()
        freeSpaceTimer = nil
    }
    
    // MARK: - Misc
    
    private func setupLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 1.0 //seconds
        tableView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Long press on a downloaded video gives the option of downloading all tracks.
        // On iOS 11, this is done here, after the main video has been downloaded.
        // In iOS 10, tracks are downloaded along with the main video.
        // Refer to OfflinePlayback.md for details.
        if #available(iOS 11.0, *) {
            
            switch gesture.state {
            case .began:
                // Find the index of the cell that was long-tapped
                let point = gesture.location(in: tableView)
                guard let indexPath = tableView.indexPathForRow(at: point), let offlineTokenArray = dataSource.offlineTokenArray, indexPath.row < offlineTokenArray.count else {
                    return
                }
                
                let token = offlineTokenArray[indexPath.row]
                if let status = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: token) {
                    if verifyDownloadStateToDownloadSecondaryTracks(status) {
                        promptToDownloadSecondaryTracks(withToken: token)
                    }
                }
            default:
                break
            }
            
        }
    }
    
    private func verifyDownloadStateToDownloadSecondaryTracks(_ status: BCOVOfflineVideoStatus) -> Bool {
        // Secondary tracks can be downloaded if...
        // The video has completed downloading...
        // or the track downloading resulted in an error...
        // or track downloading was cancelled.
        
        if (status.downloadState != .stateCompleted && status.downloadState != .stateTracksError && status.downloadState != .stateTracksCancelled) {
            // For other cases, show a warning alert and get out.
            
            var message: String?
            
            switch status.downloadState {
            case .stateTracksCompleted:
                message = "Additional tracks have already been downloaded"
                case .stateTracksRequested,
                     .stateTracksDownloading:
                message = "Additional tracks are already downloading"
            default:
                message = "Additional tracks can only be downloaded after the video has been successfully downloaded."
            }
            
            if let message = message {
                UIAlertController.show(withTitle: "Download Additional Tracks", andMessage: message)
            }
            
            return false
        }
        
        return true
    }
    
    private func promptToDownloadSecondaryTracks(withToken token: String) {
        
        guard let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: token) else {
            return
        }
        
        let name = video.properties["name"] as? String ?? "unknown"
        let message = "Download all additional tracks for the video \"\(name)\"?"
        
        print("Long press on \"\(name)\"")
        
        let alert = UIAlertController(title: "Download Additional Tracks", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Download Tracks", style: .default, handler: { [weak self] (action: UIAlertAction) in
            DownloadManager.downloadAllSecondaryTracks(forOfflineVideoToken: token)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    @objc private func updateFreeSpaceLabel() {
        
        let cMB: Double = (1000 * 1000)
        let cGB = (cMB * 1000)
        
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: "/var")
            guard let freeSizeNumber = attributes[FileAttributeKey.systemFreeSize] as? NSNumber, let fileSystemNumber = attributes[FileAttributeKey.systemSize] as? NSNumber else {
                freeSpaceLabel.text = nil
                return
            }
            
            // 1234567.890 -> @"1,234,567.9"
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
            
            let freeSizeNumberMB = NSNumber(value: freeSizeNumber.doubleValue / cMB)
            let fileSystemNumberMB = NSNumber(value: fileSystemNumber.doubleValue / cGB)
            
            guard let freeSizeString = formatter.string(from: freeSizeNumberMB), let fileSystemSizeString = formatter.string(from: fileSystemNumberMB) else {
                freeSpaceLabel.text = nil
                return
            }
            
            let freeSpaceString = "Free: \(freeSizeString) MB of \(fileSystemSizeString) GB"
            freeSpaceLabel.text = freeSpaceString
            
            if freeSizeNumber.doubleValue / cMB < 500 {
                freeSpaceLabel.textColor = .orange
            } else if freeSizeNumber.doubleValue / cMB < 100 {
                freeSpaceLabel.textColor = .red
            } else {
                freeSpaceLabel.textColor = .white
            }
            
        } catch {
            freeSpaceLabel.text = nil
        }
        
        // Check for downloads in progress as well and update the badge on the Downloads icon
        updateBadge()
    }
    
    func updateBadge() {
        guard let statusArray = BCOVOfflineVideoManager.shared()?.offlineVideoStatus() else {
            tabBarItem.badgeValue = nil
            return
        }
        
        let filteredArray = statusArray.filter({ $0.downloadState == .licensePreloaded || $0.downloadState == .stateDownloading || $0.downloadState == .stateRequested })
        
        tabBarItem.badgeValue = (filteredArray.count > 0) ? "\(filteredArray.count)" : nil
    }
    
    func updateInfoForSelectedDownload() {
 
        guard let selectedOfflineVideoToken = selectedOfflineVideoToken,
            let offlineVideoStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: selectedOfflineVideoToken),
            let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken),
            let videoID = video.properties["id"] as? String,
            let estimatedMegabytes = tabBarController?.streamingViewController()?.videoManager.estimatedDownloadSizeDictionary?[videoID] else {
                infoLabel?.text = "No video selected"
                posterImageView?.layer.borderColor = UIColor.clear.cgColor
                playButton?.setTitle("--", for: .normal)
                return
        }
        
        playButton?.setTitle("Play", for: .normal)
        
        let actualMegabytes = dataSource.downloadSizeDictionary[selectedOfflineVideoToken] ?? 0
        let startTimeNumber = video.properties[kBCOVOfflineVideoDownloadStartTimePropertyKey] as? NSNumber ?? 0
        let endTimeNumber = video.properties[kBCOVOfflineVideoDownloadEndTimePropertyKey] as? NSNumber ?? 0
        let licenseText = video.licenseString()
        let downloadState = offlineVideoStatus.downloadStateString(estimatedMegabytes: estimatedMegabytes, actualMegabytes: actualMegabytes, startTime: startTimeNumber.doubleValue, endTime: endTimeNumber.doubleValue)
        
        if let name = video.properties["name"] {
            infoLabel.text = "\(name)\nStatus: \(downloadState)\nLicense: \(licenseText)"
        }
        
    }
    
    func refresh() {
        tableView?.reloadData()
    }
    
    private func forceStopAllDownloadTasks() {
        // iOS 11.0 and 11.1 have a bug in which some downloads cannot be stopped using normal methods.
        // As a workaround, you can call "forceStopAllDownloadTasks" to cancel all the video downloads
        // that are still in progress.
        let alert = UIAlertController(title: "Stop all Downloads", message: "Do you want to stop all the downloads in progress?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Stop All", style: .destructive) { (action: UIAlertAction) in
            BCOVOfflineVideoManager.shared()?.forceStopAllDownloadTasks()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    private func cancelVideoDownload() {
        
        guard let selectedOfflineVideoToken = selectedOfflineVideoToken, let offlineVideoStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: selectedOfflineVideoToken) else {
            return
        }
        
        switch offlineVideoStatus.downloadState {
            case .stateRequested,
                 .stateTracksRequested,
                 .stateDownloading,
                 .stateTracksDownloading,
                 .stateSuspended,
                 .stateTracksSuspended:
            BCOVOfflineVideoManager.shared()?.cancelVideoDownload(selectedOfflineVideoToken)
        default:
            break
        }
    }
    
    private func logStatus() {
        // Log a variety of information to the debug console
        // about the currently selected offline video token.
        
        guard let selectedOfflineVideoToken = selectedOfflineVideoToken, let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken), let properties = video.properties else {
            print("Token unavailable or video not found")
            return
        }
        
        print("Video Properties: \(properties)")
        
        guard let sidebandCaptionsValue = video.properties[kBCOVOfflineVideoUsesSidebandSubtitleKey] as? NSNumber, let sidebandLangauges = video.properties[kBCOVOfflineVideoManagerSubtitleLanguagesKey] as? [String], sidebandCaptionsValue.boolValue == true else {
            return
        }
        
        var sidebandLanguagesString = ""
        
        for language in sidebandLangauges {
            sidebandLanguagesString = sidebandLanguagesString + language + ", "
        }

        print("Video uses sideband subtitles with languages: \(sidebandLangauges)")
    }
    
    func deleteOfflineVideo(withToken token: String) {
        // Delete the selected offline video
        
        // Remove from our local list of video tokens
        if !dataSource.removeOfflineToken(token) {
            print("Could not remove offline token from cached tokens")
            return
        }
        
        if let _ = currentlyPlayingOfflineVideoToken, currentlyPlayingOfflineVideoToken == token {
            // Hide this video if it was playing
            playButtonPressed()
        }
        
        offlineVideoWasDeletedLocally(withToken: token)
    }
    
    func offlineVideoWasDeletedLocally(withToken token: String) {
        if token == selectedOfflineVideoToken {
            resetVideoContainer()
        }
        
        selectedOfflineVideoToken = nil
        
        // Delete from storage through the offline video mananger
        BCOVOfflineVideoManager.shared()?.deleteOfflineVideo(token)
        
        // Remove poster image
        posterImageView.image = nil
        
        // Update text in info panel
        updateInfoForSelectedDownload()
        
        // Report deletion so that the video page can update download status
        tabBarController?.streamingViewController()?.updateStatus()
        
        tableView.reloadData()
    }
    
    private func updateTaskButtonTitles() {
        
        guard let token = selectedOfflineVideoToken, let status = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: token) else {
            pauseButton.setTitle("--", for: .normal)
            cancelButton.setTitle("--", for: .normal)
            return
        }
        
        switch status.downloadState {
        case .stateTracksDownloading,
             .stateDownloading:
            pauseButton.setTitle("Pause", for: .normal)
            cancelButton.setTitle("Cancel", for: .normal)
        case .stateTracksSuspended,
             .stateSuspended:
            pauseButton.setTitle("Resume", for: .normal)
            cancelButton.setTitle("Cancel", for: .normal)
        default:
            pauseButton.setTitle("--", for: .normal)
            cancelButton.setTitle("--", for: .normal)
        }
        
    }
    
    private func confirmDeletion(forVideoNamed videoName: String, withOfflineVideoToken token: String) {
        
        let alert = UIAlertController(title: "Delete Offline Video", message: "Are you sure you want to delete the offline video \"\(videoName)\"", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Delete Offline Video", style: .destructive, handler: { [weak self] (action: UIAlertAction) in
            self?.deleteOfflineVideo(withToken: token)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func resetVideoContainer() {
        playButton.setTitle("Play", for: .normal)
        playbackController = nil
        videoContainerView.alpha = 0.0
    }
    
    private func renewLicense(forOfflineVideoToken token: String) {
        
        guard let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: token), let videoID = video.properties[kBCOVVideoPropertyKeyId] as? String else {
            return
        }
        
        let licenseParmaters = DownloadManager.generateLicenseParameters()
        
        // Get updated video object to pass to renewal method
        DownloadManager.retrieveVideo(withVideoID: videoID) { (video: BCOVVideo?, jsonResponse: [AnyHashable : Any]?, error: Error?) in
            
            if let error = error {
                print("Could not retrieve new video during FairPlay license renewal. Error: \(error.localizedDescription)")
            }
            
            if let video = video {
                
                BCOVOfflineVideoManager.shared()?.renewFairPlayLicense(token, video: video, parameters: licenseParmaters, completion: { [weak self] (offlineVideoToken: String?, error: Error?) in
                    
                    if let error = error {
                        print("FairPlay license renewal completed with error: \(error.localizedDescription)")
                    }
                    
                    // Show the new license
                    
                    DispatchQueue.main.async {
                        self?.updateInfoForSelectedDownload()
                    }
                    
                })
                
            }
            
        }
        
    }
    
    // MARK: - IBActions
    
    @IBAction private func playButtonPressed() {
        
        if let _ = playbackController {
            
            resetVideoContainer()
            
        } else {
            
            guard let selectedOfflineVideoToken = selectedOfflineVideoToken else {
                return
            }
            
            let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken)
            
            playButton.setTitle("Hide", for: .normal)
            videoContainerView.alpha = 1.0
            createNewPlaybackController()
            playbackController?.setVideos([video] as NSFastEnumeration)
            currentlyPlayingOfflineVideoToken = selectedOfflineVideoToken
            
        }

    }
    
    @IBAction private func moreButtonPressed() {
        
        guard let token = selectedOfflineVideoToken, let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: token) else {
            UIAlertController.show(withTitle: "More Options", andMessage: "No video was selected")
            return
        }
        
        let name = video.properties["name"] as? String ?? "unknown"
        let message = "Additional options for offline video \"\(name)\""
        let alert = UIAlertController(title: "More Options", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Log Status", style: .default, handler: { [weak self] (action: UIAlertAction) in
            self?.logStatus()
        }))
        
        if video.usesFairPlay {
            alert.addAction(UIAlertAction(title: "Renew License", style: .default, handler: { [weak self] (action: UIAlertAction) in
                self?.renewLicense(forOfflineVideoToken: token)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Delete Offline Video", style: .default, handler: { [weak self] (action: UIAlertAction) in
            self?.confirmDeletion(forVideoNamed: name, withOfflineVideoToken: token)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func pauseButtonPressed() {
        // Pause or resume based on the current state of the download
        
        guard let selectedOfflineVideoToken = selectedOfflineVideoToken, let offlineVideoStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: selectedOfflineVideoToken) else {
            return
        }
        
        switch offlineVideoStatus.downloadState {
            case .stateDownloading,
                 .stateTracksDownloading:
            BCOVOfflineVideoManager.shared()?.pauseVideoDownload(selectedOfflineVideoToken)
            case .stateSuspended,
                 .stateTracksSuspended:
            BCOVOfflineVideoManager.shared()?.resumeVideoDownload(selectedOfflineVideoToken)
        default:
            break
        }
        
        updateInfoForSelectedDownload()
        updateTaskButtonTitles()
        tableView.reloadData()
    }
    
    @IBAction private func cancelButtonPressed() {
        if #available(iOS 11.2, *) {
            // iOS 11.2+: cancel normally
            cancelVideoDownload()
        } else if #available(iOS 11.0, *) {
            // iOS 11.0 and 11.1: work around iOS download manager bugs
            forceStopAllDownloadTasks()
        } else {
            // iOS 10.x: cancel normally
            cancelVideoDownload()
        }
    }

}

// MARK: - UITableViewDelegate

extension DownloadedVideoViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let _selectedOfflineVideoToken = dataSource.offlineTokenArray?[indexPath.row] else {
            return
        }
        
        resetVideoContainer()
        
        selectedOfflineVideoToken = _selectedOfflineVideoToken
        
        // Load poster image into the detail view
        let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: _selectedOfflineVideoToken)
        
        if let posterPathString = video?.properties[kBCOVOfflineVideoPosterFilePathPropertyKey] as? String, let posterImage = UIImage(contentsOfFile: posterPathString) {
            posterImageView.image = posterImage
        } else {
            posterImageView.image = UIImage(named: "bcov")
        }
        
        posterImageView.layer.borderColor = UIColor.lightGray.cgColor
        posterImageView.layer.borderWidth = 1
        
        updateInfoForSelectedDownload()
        
        // Update the Pause/Resume button title
        updateTaskButtonTitles()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 28
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension DownloadedVideoViewController {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        guard let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? NSError else {
            return
        }
        
        print("Error: \(error.localizedDescription)")
        
        if error.code == kBCOVOfflineVideoManagerErrorCodeExpiredLicense {
            let videoName = session.video.properties[kBCOVVideoPropertyKeyName] as? String ?? "unknown"
            UIAlertController.show(withTitle: "License Expired", andMessage: "The FairPlay license for the video \"\(videoName)\" has expired")
            resetVideoContainer()
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        if let session = session {
            sessionStartTime = Date()
            if let source = session.source {
                print("Session source details: \(source)")
            }
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        
        print("didProgressTo: \(progress)")
        
        if #available(iOS 11.0, *) {
            // No issues with playback on iOS 11
        } else {
            
            // iOS 10:
            // This is a workaround in iOS 10.x to fix an Apple bug where the video
            // does not play properly while downloading
            
            // If the seek jumps past 10 in the first 3 seconds, go back to zero.
            // This works around an Apple 10.x bug where playing downloading vidoes
            // seeks to the end of the video
            guard let _sessionStartTime = sessionStartTime else {
                return
            }
            
            let sessionStartInterval = Date().timeIntervalSince(_sessionStartTime)
            
            if (progress > 10.0 && sessionStartInterval < 3 && sessionStartInterval > 1 ) {
                sessionStartTime = nil
                controller.pause()
                controller.seek(to: .zero) { (finished: Bool) in
                    print("Seek Complete")
                    controller.play()
                }
            }
            
        }
        
    }
    
}
