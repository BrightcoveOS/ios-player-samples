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
    @State var shouldLoadVideo = true

    var body: some View {
        VStack {
            if modelData.controlType == .bcov {
                bcovPlayerUI
                    .aspectRatio(16/9, contentMode: .fit)
            } else {
                applePlayerUI
                    .aspectRatio(16/9, contentMode: .fit)
            }
            Spacer()
        }
        .onAppear {
            if shouldLoadVideo {
                let playbackController = (modelData.controlType == .bcov) ? bcovPlayerUI.playbackController : applePlayerUI.playbackController
                playbackController?.setVideos([videoListItem.video] as NSFastEnumeration)
                shouldLoadVideo = false
            }
        }
        .onDisappear {
            let playbackController = (modelData.controlType == .bcov) ? bcovPlayerUI.playbackController : applePlayerUI.playbackController
            // Clean-up for the shared PlayerUI
            if !modelData.pictureInPictureEnabled && !modelData.fullscreenEnabled {
                playbackController?.setVideos(nil)
            }
        }
        .statusBarHidden(false)
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
