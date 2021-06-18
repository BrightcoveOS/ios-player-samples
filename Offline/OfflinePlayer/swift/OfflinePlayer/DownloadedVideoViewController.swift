//
//  DownloadedVideoViewController.swift
//  OfflinePlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
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

class DownloadedVideoViewController: BaseVideoViewController {
    
    @IBOutlet weak var noVideoSelectedLabel: UILabel?
    @IBOutlet weak var downloadProgressView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton? {
        didSet {
            pauseButton?.setTitle("--", for: .normal)
        }
    }
    @IBOutlet weak var cancelButton: UIButton? {
        didSet {
            cancelButton?.setTitle("--", for: .normal)
        }
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel?
    @IBOutlet weak var freeSpaceLabel: UILabel!
    
    private var selectedOfflineVideoToken: String?
    private var currentlyPlayingOfflineVideoToken: String?
    private var freeSpaceTimer: Timer?
    private var sessionStartTime: Date?
    private var currentSession: BCOVPlaybackSession?
    
    private lazy var dataSource: DownloadsTableDataSource = {
        return DownloadsTableDataSource(tableView: tableView)
    }()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoContainerView.alpha = 0.0
        tableView.dataSource = dataSource
        updateInfoForSelectedDownload()
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
 
        updateTaskButtonTitles()
        
        guard let selectedOfflineVideoToken = selectedOfflineVideoToken,
            let offlineVideoStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: selectedOfflineVideoToken),
            let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken),
            let videoID = video.properties[kBCOVVideoPropertyKeyId] as? String,
            let estimatedMegabytes = tabBarController?.streamingViewController()?.videoManager.estimatedDownloadSizeDictionary?[videoID] else {
                noVideoSelectedLabel?.isHidden = false
                infoLabel?.isHidden = true
                posterImageView?.layer.borderColor = UIColor.clear.cgColor
                playButton?.setTitle("--", for: .normal)
                return
        }
        
        playButton?.setTitle("Play", for: .normal)
        noVideoSelectedLabel?.isHidden = true
        
        let actualMegabytes = dataSource.downloadSizeDictionary[selectedOfflineVideoToken] ?? 0
        let startTimeNumber = video.properties[kBCOVOfflineVideoDownloadStartTimePropertyKey] as? NSNumber ?? 0
        let endTimeNumber = video.properties[kBCOVOfflineVideoDownloadEndTimePropertyKey] as? NSNumber ?? 0
        let licenseText = video.licenseString()
        let downloadState = offlineVideoStatus.downloadStateString(estimatedMegabytes: estimatedMegabytes, actualMegabytes: actualMegabytes, startTime: startTimeNumber.doubleValue, endTime: endTimeNumber.doubleValue)
        
        if let name = localizedNameForLocale(video, nil) {
            infoLabel?.isHidden = false
            infoLabel?.text = "\(name)\nStatus: \(downloadState)\nLicense: \(licenseText)"
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
                 .stateDownloading,
                 .stateSuspended:
            BCOVOfflineVideoManager.shared()?.cancelVideoDownload(selectedOfflineVideoToken)
        default:
            break
        }
    }
    
    private func logStatus() {
        // Log a variety of information to the debug console
        // about the currently selected offline video token.
        
        guard let selectedOfflineVideoToken = selectedOfflineVideoToken, let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken) else {
            print("Token unavailable or video not found")
            return
        }

        let properties = video.properties

        print("Video Properties: \(properties)")
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
            pauseButton?.setTitle("--", for: .normal)
            cancelButton?.setTitle("--", for: .normal)
            return
        }
        
        switch status.downloadState {
        case .stateDownloading:
            pauseButton?.setTitle("Pause", for: .normal)
            cancelButton?.setTitle("Cancel", for: .normal)
        case .stateSuspended:
            pauseButton?.setTitle("Resume", for: .normal)
            cancelButton?.setTitle("Cancel", for: .normal)
        default:
            pauseButton?.setTitle("--", for: .normal)
            cancelButton?.setTitle("--", for: .normal)
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
        playbackController?.pause()
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
        
        // iOS 13 returns an incorrect value for `playableOffline`
        // if the offline video is already loaded into an
        // AVPlayer instance. Clearing out the current AVPlayer
        // instance solves the issue.
        if let currentSession = currentSession {
            currentSession.player.replaceCurrentItem(with: nil)
        }
        
        if let _ = playbackController {
            
            resetVideoContainer()
            currentlyPlayingOfflineVideoToken = nil
            
        } else {
            
            guard let selectedOfflineVideoToken = selectedOfflineVideoToken else {
                return
            }
            
            guard let offlineVideoStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: selectedOfflineVideoToken) else {
                return
            }
            
            let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: selectedOfflineVideoToken)
            
            if (offlineVideoStatus.downloadState == .stateCancelled) {
                UIAlertController.show(withTitle: "", andMessage: "This video is not currently playable. The download was cancelled.")
                return
            }
            
            if let _video = video {
                if (!_video.playableOffline) {
                    UIAlertController.show(withTitle: "", andMessage: "This video is not currently playable. The download may still be in progress.")
                    return
                }
            }

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
        
        let name = localizedNameForLocale(video, nil) ?? "unknown"
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
        case .stateDownloading:
            BCOVOfflineVideoManager.shared()?.pauseVideoDownload(selectedOfflineVideoToken)
        case .stateSuspended:
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
        } else {
             forceStopAllDownloadTasks()
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
            posterImageView.image = UIImage(named: "BrightcoveLogo_96_x_96")
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
            let videoName = localizedNameForLocale(session.video, nil) ?? "unknown"
            UIAlertController.show(withTitle: "License Expired", andMessage: "The FairPlay license for the video \"\(videoName)\" has expired")
            resetVideoContainer()
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        if let session = session {
            currentSession = session
            sessionStartTime = Date()
            if let source = session.source {
                print("Session source details: \(source)")
            }
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        
        print("didProgressTo: \(progress)")
    }
    
}
