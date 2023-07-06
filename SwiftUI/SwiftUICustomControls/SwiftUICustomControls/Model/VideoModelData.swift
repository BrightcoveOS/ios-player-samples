//
//  VideoModelData.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Foundation
import BrightcovePlayerSDK

struct Constants {
    static let AccountID = "5434391461001"
    static let PolicyKey =
        "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let VideoId = "5702141808001"
}

final class VideoModelData: ObservableObject {
    @Published var video: BCOVVideo?
    
    init() {
        requestVideo()
    }
    
    func requestVideo() {
        let playbackService = BCOVPlaybackService(accountId: Constants.AccountID, policyKey: Constants.PolicyKey)

        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:Constants.VideoId]
        playbackService?.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            if let video = video {
                self?.video = video
            } else {
                print("ContentView Debug - Error retrieving video: \(error!.localizedDescription)")
            }
        })
    }
}
