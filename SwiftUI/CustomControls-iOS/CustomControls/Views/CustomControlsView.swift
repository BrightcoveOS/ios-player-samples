//
//  CustomControlsView.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


struct CustomControlsView: View {

    @EnvironmentObject
    var playerModel: PlayerModel

    fileprivate let buttonSize: CGFloat = 25
    fileprivate let labelFontSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(playerModel.progress.stringFromTime)
                    .font(.system(size: labelFontSize))
                    .fontWeight(.regular)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))

                CustomSliderView {
                    ThumbnailView()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 100, height: 60)
                } onValueChanged: { _ in
                    guard let playbackController = playerModel.playbackController else { return }
                    playbackController.seek(to: CMTime(seconds: playerModel.progress,
                                                       preferredTimescale: CMTimeScale(1.0)),
                                            toleranceBefore: .zero,
                                            toleranceAfter: .zero) { sliderChangeValue in
                        if sliderChangeValue { print("Slider progress changed") }
                    }
                } onTouchSliderEvent: { _, _, isTrack in
                    guard let playbackController = playerModel.playbackController else { return }

                    withAnimation(isTrack ? .linear : nil) {
                        playerModel.isShowThumbnail = playbackController.thumbnailSeekingEnabled ? isTrack : false
                    }
                }

                Text(playerModel.duration.stringFromTime)
                    .font(.system(size: labelFontSize))
                    .fontWeight(.regular)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
            }

            HStack {
                Spacer()

                Button {
                    guard let playbackController = playerModel.playbackController else { return }
                    playbackController.seek(to: CMTime(seconds: playerModel.progress - 10,
                                                       preferredTimescale: CMTimeScale(1.0))) { back in
                        if back { print("Back - 10 second") }
                    }
                } label: {
                    Image(systemName: "gobackward.10")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }

                Button {
                    guard let playbackController = playerModel.playbackController else { return }
                    playerModel.isPlaying ? playbackController.pause() : playbackController.play()
                } label: {
                    Image(systemName: playerModel.isPlaying ? "pause" : "play")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                        .padding()
                }

                Button {
                    guard let playbackController = playerModel.playbackController else { return }
                    playbackController.seek(to: CMTime(seconds: playerModel.progress + 10,
                                                       preferredTimescale: CMTimeScale(1.0))) { next in
                        if next { print("Next + 10 second") }
                    }
                } label: {
                    Image(systemName: "goforward.10")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }

                Spacer()
            }
            .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
    }
}


// MARK: -

#if DEBUG
struct CustomControlsView_Previews: PreviewProvider {
    static var previews: some View {
        CustomControlsView()
            .environmentObject(PlayerModel())
    }
}
#endif
