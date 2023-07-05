//
//  ThumbnailView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct ThumbnailView: View {
    var video: BCOVVideo
    @ObservedObject var imageLoader:ImageLoader

    init(video: BCOVVideo) {
        self.video = video
        let urlStr = video.properties[kBCOVVideoPropertyKeyThumbnail] as? String
        imageLoader = ImageLoader(urlString:urlStr ?? "")
    }

    var body: some View {
        Image(uiImage: UIImage(data: imageLoader.data) ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width:50, height:50)
    }
}

struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailView(video: BCOVVideo(source: nil, cuePoints: nil, properties:nil))
            .previewLayout(.fixed(width: 30, height: 30))
    }
}
