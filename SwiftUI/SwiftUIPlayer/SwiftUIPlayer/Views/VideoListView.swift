//
//  VideoListView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI


enum ControlType: String, Equatable, CaseIterable, Identifiable {
    case bcov = "BCOVPUIPlayerUI"
    case native = "AVPlayerViewController"

    var id: String { rawValue }
}


struct VideoListView: View {

    @StateObject private var playlistModel = PlaylistModel()
    @ObservedObject private var playerModel = PlayerModel()

    @State private var controlType: ControlType = .bcov

    var body: some View {
        NavigationView {
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
                        VideoDetailView(playerModel: playerModel, videoItem: listItem, controlType: controlType)
                            .statusBarHidden(false)
                            .navigationTitle(listItem.name)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarBackButtonHidden(playerModel.fullscreenEnabled)
                    } label: {
                        VideoListRowView(video: listItem.video)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Videos")
        }
        .navigationViewStyle(.stack)
    }
}


// MARK: -

#if DEBUG
struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView()
    }
}
#endif
