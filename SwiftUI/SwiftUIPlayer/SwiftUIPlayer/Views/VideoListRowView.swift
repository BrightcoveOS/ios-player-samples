//
//  VideoListRowView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI

import BrightcovePlayerSDK


struct VideoListRowView: View {

    private let id: String?
    private let name: String?
    private let urlStr: String?

    let video: BCOVVideo

    init(video: BCOVVideo) {
        self.video = video
        self.id = video.properties[kBCOVVideoPropertyKeyId] as? String
        self.name = video.properties[kBCOVVideoPropertyKeyName] as? String
        self.urlStr = video.properties[kBCOVVideoPropertyKeyThumbnail] as? String
    }

    var body: some View {
        HStack {
            ThumbnailView(urlStr: urlStr)
            Divider()
            VStack(alignment: .leading) {
                Text(name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(duration())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func duration() -> String {
        guard var duration = video.properties[kBCOVVideoPropertyKeyDuration] as? Int else {
            return ""
        }
        duration = duration / 1000
        return duration.convertDurationToString()
    }
}


// MARK: -

#if DEBUG
struct VideoListRowView_Previews: PreviewProvider {
    static var previews: some View {
        let properties = [
            kBCOVVideoPropertyKeyId: "1",
            kBCOVVideoPropertyKeyName: "Test Video",
            kBCOVVideoPropertyKeyThumbnail: "https://dp6mhagng1yw3.cloudfront.net/entries/15th/b2099e83-2214-43e0-93c0-0924d12d6cdc.jpeg",
            kBCOVVideoPropertyKeyDuration: 180000
        ] as [String : Any]
        let video = BCOVVideo(source: nil, cuePoints: nil, properties: properties)

        VideoListRowView(video: video)
    }
}
#endif
