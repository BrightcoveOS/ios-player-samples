//
//  CustomControlsView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


struct CustomControlsView: View {

    @EnvironmentObject var playerModel: PlayerModel

    private let buttonSize: CGFloat = 25
    private let labelFontSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text(playerModel.progress.convertDurationToString())
                        .font(.system(size: labelFontSize))
                        .fontWeight(.regular)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                    CustomSliderView {
                        ThumbnailView()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(width: 100, height: 60)
                    } onValueChanged: { value in
                        playerModel.controller?.seek(to: CMTime(seconds: playerModel.progress, preferredTimescale: CMTimeScale(1.0)), toleranceBefore: .zero, toleranceAfter: .zero) { sliderChangeValue in
                            if sliderChangeValue { print("Slider progress changed") }
                        }
                    } onTouchSliderEvent: { _, _, isTrack in
                        withAnimation(isTrack ? .linear : nil) {
                            playerModel.isShowThumbnail = isTrack
                        }
                    }

                    Text(playerModel.duration.convertDurationToString())
                        .font(.system(size: labelFontSize))
                        .fontWeight(.regular)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                }

                HStack {
                    Spacer()

                    Button {
                        playerModel.controller?.seek(to: CMTime(seconds: playerModel.progress - 10, preferredTimescale: CMTimeScale(1.0))) { back in
                            if back { print("Back - 10 second") }
                        }
                    } label: {
                        Image(systemName: "gobackward.10")
                            .resizable()
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    Button {
                        playerModel.isPlaying ? playerModel.controller?.pause() : playerModel.controller?.play()
                    } label: {
                        Image(systemName: playerModel.isPlaying ? "pause" : "play")
                            .resizable()
                            .frame(width: buttonSize, height: buttonSize)
                            .padding()
                    }

                    Button {
                        playerModel.controller?.seek(to: CMTime(seconds: playerModel.progress + 10, preferredTimescale: CMTimeScale(1.0))) { next in
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
