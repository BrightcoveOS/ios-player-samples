//
//  VideoDetail.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct VideoDetail: View {
    var videoListItem: VideoListItem
    
    init(videoListItem: VideoListItem) {
        self.videoListItem = videoListItem
    }

    var body: some View {
        VStack {
            playerUI
                .aspectRatio(16/9, contentMode: .fit)
            Spacer()
        }
        .onAppear {
            playerUI.playbackController?.setVideos([videoListItem.video] as NSFastEnumeration)
        }
        .onDisappear {
            // Clean-up for the shared PlayerUI
            if !playerUI.pictureInPictureEnabled {
                playerUI.playbackController?.setVideos(nil)
            }
            if playerUI.fullscreenEnabled {
                playerUI.playerView.performScreenTransition(with: .normal)
            }
        }
        .navigationTitle(videoListItem.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VideoDetail_Previews: PreviewProvider {
    static let videoListItem = VideoListItem(id: "1", name: "Test Video", video: BCOVVideo(source: nil, cuePoints: nil, properties: nil))
    static var previews: some View {
        VideoDetail(videoListItem: videoListItem)
    }
}
