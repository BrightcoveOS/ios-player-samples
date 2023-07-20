//
//  VideoDetail.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct VideoDetail: View {
    @EnvironmentObject var modelData: ModelData

    var videoListItem: VideoListItem

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
            if !modelData.pictureInPictureEnabled {
                playerUI.playbackController?.setVideos(nil)
            }
            if modelData.fullscreenEnabled {
                playerUI.playerView.performScreenTransition(with: .normal)
            }
        }
        .navigationTitle(videoListItem.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(modelData.fullscreenEnabled)
    }
}

struct VideoDetail_Previews: PreviewProvider {
    static let videoListItem = VideoListItem(id: "1", name: "Test Video", video: BCOVVideo(source: nil, cuePoints: nil, properties: nil))
    static var previews: some View {
        VideoDetail(videoListItem: videoListItem)
    }
}
