//
//  VideoModel.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Combine

import BrightcovePlayerSDK


struct Constants {
    static let AccountID = "5434391461001"
    static let PolicyKey =
        "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let VideoId = "5702141808001"
}


final class VideoModel {
    func requestVideo() -> Future<BCOVVideo, Error> {
        return Future<BCOVVideo, Error> { promise in
            let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:Constants.VideoId]
            let playbackService = BCOVPlaybackService(accountId: Constants.AccountID, policyKey: Constants.PolicyKey)

            playbackService?.findVideo(withConfiguration: configuration, queryParameters: nil) { video, jsonResponse, error in
                if let video = video {
                    promise(.success(video))
                } else {
                    promise(.failure(error ?? NSError()))
                }
            }
        }
    }
}

