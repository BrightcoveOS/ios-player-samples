//
//  ViewController.swift
//  MultiplePlayersSample
//
//  Created by Jeremy Blaker on 6/9/22.
//

import UIKit
import BrightcovePlayerSDK

struct ConfigConstants {
    static let AccountID = "5434391461001"
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let PlaylistId = "1735168388684004403"
}

class PlaybackConfiguration {
    var playbackController: BCOVPlaybackController?
    var playbackSession: BCOVPlaybackSession?
}

class ViewController: UITableViewController {

    public static let ScrollingStoppedNotification = Notification.Name("ScrollingStoppedNotification")
    public static let ScrollingStartedNotification = Notification.Name("ScrollingStartedNotification")
    
    var playbackConfigurations = [String:PlaybackConfiguration]()
    var videos: [BCOVVideo]?
    var isScrolling = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 290

        requestPlaylist()
    }
    
    private func requestPlaylist() {
        let playbackService = BCOVPlaybackService(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PolicyKey)
        
        playbackService?.findPlaylist(withPlaylistID: ConfigConstants.PlaylistId, parameters: nil, completion: { [weak self] (playlist: BCOVPlaylist?, json: [AnyHashable:Any]?, error: Error?) in
            
            if let error = error {
                print("Failed to fetch playlist: \(error.localizedDescription)")
                return
            }
            
            if let videos = playlist?.videos as? [BCOVVideo] {
                self?.videos = videos
                self?.setUpPlaybackControllers()
            }
            
        })
    }

    private func setUpPlaybackControllers() {
        
        guard let videos = videos else {
            return
        }
        
        for video in videos {

            guard let videoId = video.properties[kBCOVVideoPropertyKeyId] as? String,
                  let newPlaybackController = BCOVPlayerSDKManager.shared().createPlaybackController()
            else {
                continue
            }
            
            // Optimize buffering by keeping them at low values
            // so the multiple players don't use up too much memory
            // https://github.com/brightcove/brightcove-player-sdk-ios#BufferOptimization
            if var options = newPlaybackController.options {
                options[kBCOVBufferOptimizerMethodKey] = NSNumber(value: BCOVBufferOptimizerMethod.default.rawValue)
                options[kBCOVBufferOptimizerMinimumDurationKey] = 1
                options[kBCOVBufferOptimizerMaximumDurationKey] = 5
                newPlaybackController.options = options
            }
            newPlaybackController.delegate = self

            // Caching the thumbnail images for multiple videos
            // will use up a lot of memory so we'll disable this feature
            newPlaybackController.thumbnailSeekingEnabled = false
            
            let playbackConfiguration = PlaybackConfiguration()
            playbackConfiguration.playbackController = newPlaybackController
            
            playbackConfigurations[videoId] = playbackConfiguration

            newPlaybackController.setVideos([video] as NSFastEnumeration)
        }
        
        self.tableView.reloadData()
    }
    
    internal func tableScrollingStopped() {
        // Scrolling stopped, let the active cells know they
        // so they can begin playback
        NotificationCenter.default.post(name: ViewController.ScrollingStoppedNotification, object: nil)
        isScrolling = false
    }

}

// MARK: - UITableViewDataSource

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell") as? VideoTableViewCell,
              let video = videos?[indexPath.row],
              let videoId = video.properties[kBCOVVideoPropertyKeyId] as? String,
              let playbackConfiguration = playbackConfigurations[videoId]
        else {
            return UITableViewCell()
        }

        cell.setUpWith(video: video, playbackConfiguration: playbackConfiguration)
        
        // If we aren't scrolling when this cell is configured
        // go ahead and play!
        if !isScrolling {
            playbackConfiguration.playbackController?.play()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 290
    }

}

// MARK: - UIScrollViewDelegate

extension ViewController {
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            tableScrollingStopped()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        tableScrollingStopped()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // The table view has begun being scrolled
        // let the active table cells know so that they
        // can pause their videos.
        NotificationCenter.default.post(name: ViewController.ScrollingStartedNotification, object: nil)
        isScrolling = true
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController : BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        guard let videoId = session.video.properties[kBCOVVideoPropertyKeyId] as? String, let playbackConfiguration = playbackConfigurations[videoId] else {
            return
        }
        
        session.player.isMuted = true
        playbackConfiguration.playbackSession = session
    }
    
}
