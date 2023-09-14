//
//  VideoDetailView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI

import BrightcovePlayerSDK

struct VideoDetailView: View {

    @State private var didSetVideo = false

    let playerModel: PlayerModel
    let videoItem: VideoListItem
    let controlType: ControlType

    var body: some View {
        VStack {
            VStack {
                if controlType == .bcov {
                    BCOVPlayerUIView(playerModel: playerModel)
                } else {
                    ApplePlayerUIView(playerModel: playerModel)
                }
            }
            .navigationBarBackButtonHidden(playerModel.fullscreenEnabled)
            .aspectRatio(16/9, contentMode: .fit)
            Spacer()
        }
        .onAppear {
            if !didSetVideo {
                playerModel.controller?.setVideos([videoItem.video] as NSFastEnumeration)
                didSetVideo.toggle()
            }
        }
        .onDisappear {
            if !playerModel.fullscreenEnabled && !playerModel.pictureInPictureEnabled {
                playerModel.controller?.setVideos(nil)
            }
        }
    }
}


// MARK: -

#if DEBUG
struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let playerModel = PlayerModel()
        let video = BCOVVideo(source: nil, cuePoints: nil, properties: nil)
        let videoListItem = VideoListItem(id: "1", name: "Test Video", video: video)
        VideoDetailView(playerModel: playerModel, videoItem: videoListItem, controlType: .bcov)
    }
}
#endif
