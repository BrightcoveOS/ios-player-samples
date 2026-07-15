//
//  VideoModel.swift
//  CustomControls
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import Combine
import BrightcovePlayerSDK


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"

final class VideoModel {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    func requestContentFromPlaybackService() -> Future<BCOVVideo, Error> {
        Future<BCOVVideo, Error> { [self] promise in
            let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]

            playbackService.findVideo(withConfiguration: configuration,
                                      queryParameters: nil) { [promise] (video: BCOVVideo?,
                                                                         jsonResponse: Any?,
                                                                         error: Error?) in
                if let video {
                    promise(.success(video))
                } else {
                    promise(.failure(error ?? NSError()))
                }
            }
        }
    }
}

