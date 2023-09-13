//
//  PlaylistModel.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Foundation

import BrightcovePlayerSDK


struct Constants {
    static let AccountID = "5434391461001"
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let PlaylistRefID = "brightcove-native-sdk-plist"
}


final class PlaylistModel: ObservableObject {

    @Published var videoListItems = [VideoListItem]()

    init() {
        requestPlaylist()
    }

    private func requestPlaylist() {
        let playbackService = BCOVPlaybackService(accountId: Constants.AccountID, policyKey: Constants.PolicyKey)

        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetReferenceID:Constants.PlaylistRefID]

        playbackService?.findPlaylist(withConfiguration: configuration, queryParameters: nil) { [weak self] playlist, jsonResponse, error in
            if let playlist = playlist, let videos = playlist.videos as? [BCOVVideo] {
                var _videoListItems = [VideoListItem]()
                for video in videos {
                    guard let videoId = video.properties[kBCOVVideoPropertyKeyId] as? String, let videoName = video.properties[kBCOVVideoPropertyKeyName] as? String else {
                        continue
                    }
                    let video = VideoListItem(id: videoId, name: videoName, video: video)
                    _videoListItems.append(video)
                }
                self?.videoListItems = _videoListItems
            } else {
                print("PlaylistModel Debug - Error retrieving video playlist: \(error!.localizedDescription)")
            }
        }
    }
}
