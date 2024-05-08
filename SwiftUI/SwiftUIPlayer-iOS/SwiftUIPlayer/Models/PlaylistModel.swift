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
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    init() {
        requestContentFromPlaybackService()
    }

    fileprivate func requestContentFromPlaybackService() {

        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetReferenceID: kPlaylistRefId]

        playbackService.findPlaylist(withConfiguration: configuration, queryParameters: nil) {
            [weak self] (playlist: BCOVPlaylist?,
                         jsonResponse: [AnyHashable: Any]?,
                         error: Error?) in

            guard let playlist,
                  let videos = playlist.videos as? [BCOVVideo] else {
                if let error {
                    print("PlaylistModel - Error retrieving video playlist: \(error.localizedDescription)")
                }
                
                return
            }

            var videoListItems = [VideoListItem]()
            for video in videos {
                guard let videoId = video.properties[kBCOVVideoPropertyKeyId] as? String,
                      let videoName = video.properties[kBCOVVideoPropertyKeyName] as? String else {
                    continue
                }

                let video = VideoListItem(id: videoId, name: videoName, video: video)
                videoListItems.append(video)
            }

            self?.videoListItems = videoListItems
        }
    }
}
