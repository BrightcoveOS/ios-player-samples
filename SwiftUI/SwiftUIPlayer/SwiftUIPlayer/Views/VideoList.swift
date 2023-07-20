//
//  VideoList.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct VideoList: View {
    @StateObject private var modelData = ModelData()
    
    var body: some View {
        NavigationView {
            List(modelData.videoListItems) { listItem in
                NavigationLink {
                    VideoDetail(videoListItem: listItem)
                } label: {
                    VideoListRow(listItem: listItem)
                }
            }
            .navigationTitle("Videos")
        }
        .navigationViewStyle(.stack)
        .environmentObject(modelData)
    }
}

struct VideoList_Previews: PreviewProvider {
    static var previews: some View {
        VideoList()
    }
}
