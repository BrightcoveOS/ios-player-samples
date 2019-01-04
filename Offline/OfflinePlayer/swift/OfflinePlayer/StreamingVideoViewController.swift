//
//  StreamingVideoViewController.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

struct ConfigConstants {
    static let AccountID = "5434391461001"
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let PlaylistID = "brightcove-native-sdk-plist"
}

// The Videos View Controller displays a list of HLS videos retrieved
// from a Brightcove Dynamic Delivery account playlist.
// You can tap the download button on a video to begin downloading the video.

class StreamingVideoViewController: BaseVideoViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 65
        }
    }
    @IBOutlet weak var unavailableView: UIView!
    
    lazy var videoManager: VideoManager = {
        let _videoManager = VideoManager()
        _videoManager.delegate = self
        return _videoManager
    }()
    
    lazy var downloadManager: DownloadManager = {
        let _downloadManager = DownloadManager()
        _downloadManager.delegate = self
        return _downloadManager
    }()
    
    private lazy var dataSource: StreamingTableDataSource = {
        return StreamingTableDataSource(tableView: tableView, videoManager: videoManager, downloadManager: downloadManager)
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let _refreshControl = UIRefreshControl()
        _refreshControl.addTarget(self, action: #selector(handleTableRefresh(_:)), for: .valueChanged)
        return _refreshControl
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        tableView.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(analyticsStorageFullWarningNotificationReceived(_:)), name: NSNotification.Name.bcovOfflineVideoManagerAnalyticsStorageFullWarning, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatus), name: OfflinePlayerNotifications.UpdateStatus, object: nil)
        
        if let downloadsVC = tabBarController?.downloadsViewController() {
            downloadsVC.updateBadge()
        }
        
        let off = NSNumber(booleanLiteral: false)
        
        let options = [kBCOVOfflineVideoManagerAllowsCellularDownloadKey: off, kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: off, kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: off]
        BCOVOfflineVideoManager.initializeOfflineVideoManager(with: downloadManager, options: options)
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showWarnings()
    }
    
    // MARK: - IBActions
    
    @IBAction private func retryButtonWasPressed() {
        tableView.isHidden = false
        unavailableView.isHidden = true
        retrievePlaylist()
    }
    
    // MARK: - Misc
    
    private func setup() {
        createNewPlaybackController()
        retrievePlaylist()
    }
    
    private func retrievePlaylist() {
        refreshControl.beginRefreshing()
        
        let queryParams = ["limit": 100, "offset": 0]
        
        // Retrieve a playlist through the BCOVPlaybackService
        let playbackServiceRequestFactory = BCOVPlaybackServiceRequestFactory(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PolicyKey)
        
        let playbackService = BCOVPlaybackService(requestFactory: playbackServiceRequestFactory)
        playbackService?.findPlaylist(withReferenceID: ConfigConstants.PlaylistID, parameters: queryParams, completion: { [weak self] (playlist: BCOVPlaylist?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            self?.refreshControl.endRefreshing()
            
            if let playlist = playlist, let videos = playlist.videos as? [BCOVVideo], let bitrate = self?.tabBarController?.settingsViewController()?.bitrate() {
                self?.videoManager.currentVideos = videos
                self?.videoManager.currentPlaylistTitle = playlist.properties["name"] as? String
                self?.videoManager.currentPlaylistDescription = playlist.properties["description"] as? String
                
                self?.videoManager.usePlaylist(videos, withBitrate: bitrate)
            } else {
                print("No playlist for ID \"\(ConfigConstants.PlaylistID)\" was found.")
                self?.tableView.isHidden = true
                self?.unavailableView.isHidden = false
            }
            
        })
    }

    @objc private func analyticsStorageFullWarningNotificationReceived(_ notification: Notification) {
        UIAlertController.show(withTitle: "Analytics storage is full", andMessage: "Encourage the app user to go online")
    }
    
    @objc private func handleTableRefresh(_ refreshControl: UIRefreshControl) {
        retrievePlaylist()
    }
    
    @objc func updateStatus() {
        videoManager.updateStatusForPlaylist()
        tabBarController?.downloadsViewController()?.updateBadge()
        tableView.reloadData()
    }
    
    private func showWarnings() {
        #if targetEnvironment(simulator)
        UIAlertController.show(withTitle: "Reminder...", andMessage: "FairPlay videos won't download or display in a simulator.")
        #endif
        
        if ConfigConstants.AccountID.count == 0 {
            UIAlertController.show(withTitle: "Invalid account information", andMessage: "Don't forget to enter your account information at the top of VideosViewController.swift")
        }
    }
    
    

}

// MARK: - UITableViewDelegate

extension StreamingVideoViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 28
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        
        if let videoDictionary = videoManager.videosTableViewData?[indexPath.row], let video = videoDictionary["video"] as? BCOVVideo {
            playbackController?.setVideos([video] as NSFastEnumeration)
        }
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension StreamingVideoViewController {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if let eventType = lifecycleEvent.eventType, let error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError] as? Error {
            if eventType == kBCOVPlaybackSessionLifecycleEventFail {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        // This method is called when ready to play a new video
        if let source = session.source {
            print("Session source details: \(source)")
        }
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        // This is where you can track playback progress of offline or online videos
    }
    
}

// MARK: - ReloadDelegate

extension StreamingVideoViewController: ReloadDelegate {

    func reloadRow(forVideo video: BCOVVideo) {
        guard let videosTableViewData = videoManager.videosTableViewData else {
            return
        }
        var index = 0
        for videoDictionary in videosTableViewData {
            if let _video = videoDictionary["video"] as? BCOVVideo {
                if (_video.matches(offlineVideo: video)) {
                    if let name = video.properties["name"] as? String {
                        print("Reloading row for video \"\(name)\"")
                    }
                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    break
                }
            }
            index = index + 1
        }
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
}

