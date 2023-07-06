//
//  VideoListRow.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct VideoListRow: View {
    var listItem: VideoListItem

    var body: some View {
        HStack {
            ThumbnailView(video: listItem.video)
            Divider()
            VStack(alignment: .leading) {
                Text(listItem.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(listItem.duration())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct VideoListRow_Previews: PreviewProvider {
    static let videoListItem = VideoListItem(id: "1", name: "Test", video: BCOVVideo(source: nil, cuePoints: nil, properties: nil))
    static var previews: some View {
        VideoListRow(listItem: videoListItem)
    }
}
