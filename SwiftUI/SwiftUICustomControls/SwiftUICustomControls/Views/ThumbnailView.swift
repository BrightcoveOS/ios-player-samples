//
//  ThumbnailView.swift
//  SwiftUICustomControls
//
//  Created by iletai on 05/03/2024.
//

import Foundation
import SwiftUI

struct ThumbnailView: View {
    @EnvironmentObject var playerModel: PlayerModel
    var body: some View {
        if playerModel.isShowThumbnail {
            if let image = playerModel.thumbnailManager?.thumbnailAtTime(playerModel.progress.asCMTime) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
            } else {
                loadingView
            }
        }
    }

    /// Loading View
    var loadingView: some View {
        Color
            .gray
            .opacity(0.2)
            .overlay(ProgressView())
    }
}
