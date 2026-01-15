//
//  PlaylistModel.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Foundation
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kPlaylistRefId = "brightcove-native-sdk-plist"


final class PlaylistModel: ObservableObject {

    @Published
    var videoListItems = [VideoListItem]()

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    init() {
        requestContentFromPlaybackService()
    }

    fileprivate func requestContentFromPlaybackService() {

        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetReferenceID: kPlaylistRefId]

        playbackService.findPlaylist(withConfiguration: configuration, queryParameters: nil) {
            [weak self] (playlist: BCOVPlaylist?,
                         jsonResponse: Any?,
                         error: Error?) in

            guard let playlist else {
                if let error {
                    print("PlaylistModel - Error retrieving video playlist: \(error.localizedDescription)")
                }
                
                return
            }

            let videos = playlist.videos

            var videoListItems = [VideoListItem]()
            for video in videos {
                guard let videoId = video.properties[BCOVVideo.PropertyKeyId] as? String,
                      let videoName = video.properties[BCOVVideo.PropertyKeyName] as? String else {
                    continue
                }

                let video = VideoListItem(id: videoId, name: videoName, video: video)
                videoListItems.append(video)
            }

            self?.videoListItems = videoListItems
        }
    }
}
