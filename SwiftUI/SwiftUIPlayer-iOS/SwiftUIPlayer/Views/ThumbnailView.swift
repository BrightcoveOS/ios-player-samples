//
//  ThumbnailView.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


struct ThumbnailView: View {

    @ObservedObject
    var imageLoader:ImageLoader

    let urlStr: String?

    init(urlStr: String?) {
        self.urlStr = urlStr
        imageLoader = ImageLoader(urlString: urlStr ?? "")
    }

    var body: some View {
        Image(uiImage: UIImage(data: imageLoader.data) ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width:50, height:50)
    }
}


// MARK: -

#if DEBUG
struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        let urlStr = "https://dp6mhagng1yw3.cloudfront.net/entries/15th/b2099e83-2214-43e0-93c0-0924d12d6cdc.jpeg"
        ThumbnailView(urlStr: urlStr)
    }
}
#endif
