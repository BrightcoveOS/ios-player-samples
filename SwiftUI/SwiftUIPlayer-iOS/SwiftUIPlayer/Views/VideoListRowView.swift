//
//  VideoListRowView.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


struct VideoListRowView: View {

    fileprivate var id: String? {
        return video.properties[kBCOVVideoPropertyKeyId] as? String
    }

    fileprivate var name: String? {
        return video.properties[kBCOVVideoPropertyKeyName] as? String
    }

    fileprivate var urlStr: String? {
        return video.properties[kBCOVVideoPropertyKeyThumbnail] as? String
    }

    fileprivate var duration: String {
        guard var duration = video.properties[kBCOVVideoPropertyKeyDuration] as? TimeInterval else {
            return ""
        }

        duration = duration / 1000
        return duration.stringFromTime
    }

    let video: BCOVVideo

    var body: some View {
        HStack {
            ThumbnailView(urlStr: urlStr)
            Divider()
            VStack(alignment: .leading) {
                Text(name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(duration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
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
            kBCOVVideoPropertyKeyDuration: 180000 as TimeInterval
        ] as [String : Any]
        let video = BCOVVideo(source: nil, cuePoints: nil, properties: properties)

        VideoListRowView(video: video)
    }
}
#endif
