//
//  VideoListView.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI


enum ControlType: String, Equatable, CaseIterable, Identifiable {
    case bcov = "BCOVPUIPlayer"
    case native = "AVPlayerViewController"

    var id: String { rawValue }
}


struct VideoListView: View {

    @StateObject
    fileprivate var playlistModel = PlaylistModel()

    @ObservedObject
    var playerModel: PlayerModel

    @State
    fileprivate var controlType: ControlType = .bcov

    @State
    fileprivate var isShowingDetailView = false

    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading) {
                    Text("Control Type")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Picker("ControlType", selection: $controlType) {
                        ForEach(ControlType.allCases) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()

                List(playlistModel.videoListItems) { listItem in
                    NavigationLink {
                        VideoDetailView(playerModel: playerModel,
                                        videoItem: listItem,
                                        controlType: controlType)
                        .navigationTitle(listItem.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
                        .statusBarHidden(playerModel.fullscreenEnabled)
                        .toolbar(playerModel.fullscreenEnabled ? .hidden : .visible, for: .tabBar)
                        .toolbar(playerModel.fullscreenEnabled ? .hidden : .visible, for: .navigationBar)
                    } label: {
                        VideoListRowView(video: listItem.video)
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Videos")
        }
    }

}


// MARK: -

#if DEBUG
struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView(playerModel: PlayerModel())
    }
}
#endif
