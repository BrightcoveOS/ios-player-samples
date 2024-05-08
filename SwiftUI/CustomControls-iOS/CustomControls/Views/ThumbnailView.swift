//
//  ThumbnailView.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Foundation
import SwiftUI


struct ThumbnailView: View {

    @EnvironmentObject
    var playerModel: PlayerModel

    var body: some View {
        if playerModel.isShowThumbnail {
            if let thumbnailManager = playerModel.thumbnailManager,
               let image = thumbnailManager.thumbnailAtTime(playerModel.progress.asCMTime) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color
                    .gray
                    .opacity(0.2)
                    .overlay(ProgressView())
            }
        }
    }
}


// MARK: -

#if DEBUG
struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailView()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: 100, height: 60)
            .environmentObject(PlayerModel())
    }
}
#endif
