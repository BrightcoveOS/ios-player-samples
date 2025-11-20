//
//  VideoDetailView.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


struct VideoDetailView: View {

    @Environment(\.dismiss)
    fileprivate var dismiss

    @State
    fileprivate var didSetVideo = false

#if targetEnvironment(simulator)
    @State
    fileprivate var showFairPlayWarning = false
#endif

    let playerModel: PlayerModel
    let videoItem: VideoListItem
    let controlType: ControlType

    var body: some View {
        VStack {
            VStack {
                switch controlType {
                case .bcov:
                    BCOVPlayerUIView(playerModel: playerModel)
                case .bcovViewController:
                    BCOVPlayerViewControllerRepresentable(playerModel: playerModel)
                case .native:
                    ApplePlayerUIView(playerModel: playerModel)
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    if let playbackController = playerModel.playbackController,
                       !playerModel.fullscreenEnabled,
                       !playerModel.pictureInPictureEnabled {
                        playbackController.setVideos(nil)
                    }

                    dismiss()
                }, label: {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 11))
                        Text("Videos")
                    }
                })
            }
        }
        .onAppear {
            guard let playbackController = playerModel.playbackController else { return }

            if !didSetVideo {
#if targetEnvironment(simulator)
                if videoItem.video.usesFairPlay {
                    showFairPlayWarning.toggle()
                    return
                }
#endif
                playbackController.setVideos([videoItem.video])
                didSetVideo.toggle()
            }
        }
#if targetEnvironment(simulator)
        .alert(isPresented: $showFairPlayWarning) { () -> Alert in
            Alert(title: Text("FairPlay Warning"),
                  message: Text("FairPlay only works on actual iOS or tvOS devices.\n\nYou will not be able to view any FairPlay content in the iOS or tvOS simulator."),
                  dismissButton: .default(Text("Ok")))
        }
#endif
    }
}


// MARK: -

#if DEBUG
struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let playerModel = PlayerModel()
        let video = BCOVVideo(withSource: nil,
                              cuePoints: nil,
                              properties: nil)
        let videoListItem = VideoListItem(id: "1",
                                          name: "Test Video",
                                          video: video)
        VideoDetailView(playerModel: playerModel,
                        videoItem: videoListItem,
                        controlType: .bcov)
    }
}
#endif
