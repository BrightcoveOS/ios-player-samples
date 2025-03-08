//
//  VideoManager.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kPlaylistRefId = "brightcove-native-sdk-plist"


final class VideoManager: NSObject {

    static var shared = VideoManager()

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate(set) lazy var videos: [BCOVVideo] = .init()
    fileprivate(set) lazy var thumbnails: [String: UIImage] = .init()
    fileprivate(set) lazy var downloadSize: [String: Double] = .init()

    func retrievePlaylist(with configuration: [String: Any],
                          queryParameters: [String: Any]?,
                          completion: @escaping (BCOVPlaylist?, [AnyHashable: Any]?, Error?) -> Void) {

        playbackService.findPlaylist(withConfiguration: configuration, queryParameters: queryParameters) {
            (playlist: BCOVPlaylist?, jsonResponse: Any?, error: Error?) in
            completion(playlist, jsonResponse as? [AnyHashable : Any], error)
        }
    }

    func retrieveVideo(_ video: BCOVVideo,
                       completion: @escaping (BCOVVideo?, [AnyHashable: Any]?, Error?) -> Void) {
        guard let videoId = video.videoId else {
            return
        }

        let configuration: [String: Any] = [ BCOVPlaybackService.ConfigurationKeyAssetID: videoId ]
        playbackService.findVideo(withConfiguration: configuration , queryParameters: nil) {
            (video: BCOVVideo?, jsonResponse: Any?, error: Error?) in
            completion(video, jsonResponse as? [AnyHashable : Any], error)
        }
    }

    func usePlaylist(_ playlist: [BCOVVideo],
                     with bitrate: Int) {

        videos = playlist
        thumbnails = .init()
        downloadSize = .init()

        for video in videos {
            estimateDownloadSize(for: video,
                                 with: bitrate)

            cacheThumbnail(for: video)
        }

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: nil)
    }

    fileprivate func estimateDownloadSize(for video: BCOVVideo,
                                          with bitrate: Int) {
        // Estimate download size for each video
        guard let videoId = video.videoId,
              let offlineManager = BCOVOfflineVideoManager.sharedManager else {
            return
        }

        let options = [BCOVOfflineVideoManager.RequestedBitrateKey: bitrate]

        offlineManager.estimateDownloadSize(video, options: options) {
            (megabytes: Double, error: Error?) in

            DispatchQueue.main.async { [self] in
                downloadSize[videoId] = megabytes

                NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                                object: video)
            }
        }
    }

    fileprivate func cacheThumbnail(for video: BCOVVideo) {
        // videoId is the key in the image cache dictionary
        guard let videoId = video.videoId,
              let sources = video.properties[BCOVVideo.PropertyKeyThumbnailSources] as? [[String: Any]] else {
            return
        }

        for thumbnail in sources {
            guard let urlString = thumbnail["src"] as? String,
                  let url = URL(string: urlString),
                  let scheme = url.scheme,
                  scheme.caseInsensitiveCompare(BCOVSource.URLSchemeHTTPS) == .orderedSame else {
                continue
            }

            DispatchQueue.global(qos: .background).async {
                var thumbnailImageData: Data?

                do {
                    thumbnailImageData = try Data(contentsOf: url)
                } catch {
                    print("Error getting thumbnail image data: \(error.localizedDescription)")
                }

                guard let thumbnailImageData,
                      let thumbnailImage = UIImage(data: thumbnailImageData) else {
                    return
                }

                DispatchQueue.main.async { [self] in
                    thumbnails[videoId] = thumbnailImage

                    NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                                    object: video)
                }
            }
        }
    }
}
