//
//  ViewController.swift
//  TableViewPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kPlaylistId = "1735168388684004403"


let ScrollingStoppedNotification = Notification.Name("ScrollingStoppedNotification")
let ScrollingStartedNotification = Notification.Name("ScrollingStartedNotification")


final class PlaybackConfiguration {
    var playbackController: BCOVPlaybackController?
    var playbackSession: BCOVPlaybackSession?
}


final class ViewController: UITableViewController {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playbackConfigurations = [String: PlaybackConfiguration]()
    fileprivate lazy var videos: [BCOVVideo]? = nil {
        didSet {
            guard let videos else { return }

            for video in videos {
                guard let videoId = video.properties[BCOVVideo.PropertyKeyId] as? String else {
                    continue
                }

                let sdkManager = BCOVPlayerSDKManager.sharedManager()
                let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                               applicationId: nil)

                let newPlaybackController = sdkManager.createFairPlayPlaybackController(withAuthorizationProxy: authProxy)
                newPlaybackController.delegate = self

                // Optimize buffering by keeping them at low values
                // so the multiple players don't use up too much memory
                // https://github.com/brightcove/brightcove-player-sdk-ios#BufferOptimization
                if var options = newPlaybackController.options {
                    options[kBCOVBufferOptimizerMethodKey] = NSNumber(value: BCOVBufferOptimizerMethod.default.rawValue)
                    options[kBCOVBufferOptimizerMinimumDurationKey] = 1
                    options[kBCOVBufferOptimizerMaximumDurationKey] = 5
                    newPlaybackController.options = options
                }

                // Caching the thumbnail images for multiple videos
                // will use up a lot of memory so we'll disable this feature
                newPlaybackController.thumbnailSeekingEnabled = false

                let playbackConfiguration = PlaybackConfiguration()
                playbackConfiguration.playbackController = newPlaybackController

                playbackConfigurations[videoId] = playbackConfiguration

                newPlaybackController.setVideos([video])
            }

            tableView.reloadData()
        }
    }

    fileprivate lazy var isScrolling = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 300

        requestContentFromPlaybackService()
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [ BCOVPlaybackService.ConfigurationKeyAssetID: kPlaylistId]
        playbackService.findPlaylist(withConfiguration: configuration,
                                     queryParameters: nil) {
            [self] (playlist: BCOVPlaylist?,
                    json: Any?,
                    error: Error?) in
            guard let playlist else {
                if let error {
                    print("ViewController - Error retrieving video playlist: \(error.localizedDescription)")
                }

                return
            }

            let videos = playlist.videos

#if targetEnvironment(simulator)
            self.videos = videos.filter({ !$0.usesFairPlay })
#else
            self.videos = videos
#endif
        }
    }

    fileprivate func tableScrollingStopped() {
        // Scrolling stopped, let the active cells know they
        // so they can begin playback
        NotificationCenter.default.post(name: ScrollingStoppedNotification,
                                        object: nil)
        isScrolling = false
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController : BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {

        guard let videoId = session.video.properties[BCOVVideo.PropertyKeyId] as? String,
              let currentItem = session.player.currentItem,
              let playbackConfiguration = playbackConfigurations[videoId] else {
            return
        }

        session.player.isMuted = true
        playbackConfiguration.playbackSession = session

        if currentItem.duration.isIndefinite,
           let videos {
            self.videos = videos.filter({ $0.properties[BCOVVideo.PropertyKeyId] as? String != videoId })
            playbackConfigurations.removeValue(forKey: videoId)
            tableView.reloadData()
        }
    }
}


// MARK: - UITableViewDataSource

extension ViewController {

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard let videos else { return 0}
        return videos.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell") as? VideoTableViewCell,
              let video = videos?[indexPath.row],
              let videoId = video.properties[BCOVVideo.PropertyKeyId] as? String,
              let playbackConfiguration = playbackConfigurations[videoId] else {
            return UITableViewCell()
        }

        cell.setUpWith(video: video,
                       playbackConfiguration: playbackConfiguration)

        // If we aren't scrolling when this cell is configured
        // go ahead and play!
        if !isScrolling,
           let playbackController = playbackConfiguration.playbackController {
            playbackController.play()
        }

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}


// MARK: - UIScrollViewDelegate

extension ViewController {

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                           willDecelerate decelerate: Bool) {
        if !decelerate {
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
        NotificationCenter.default.post(name: ScrollingStartedNotification,
                                        object: nil)
        isScrolling = true
    }
}
