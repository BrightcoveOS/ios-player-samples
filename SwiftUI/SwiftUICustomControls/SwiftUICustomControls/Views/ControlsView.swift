//
//  ControlsView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct ControlsView: View {
    @EnvironmentObject var playerStateModelData: PlayerStateModelData
    
    var playerUI: PlayerUI
    var buttonSize: CGFloat = 25
    var labelFontSize: CGFloat = 15
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(playerStateModelData.progress.convertDurationToString())
                    .font(.system(size: labelFontSize))
                    .fontWeight(.regular)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))

                CustomSliderView(value: $playerStateModelData.progress) { value in
                    playerUI.playbackController?.seek(to: CMTime(seconds: playerStateModelData.progress, preferredTimescale: CMTimeScale(1.0)), toleranceBefore: .zero, toleranceAfter: .zero) { sliderChangeValue in
                        if sliderChangeValue { print("Slider progress changed") }
                    }
                }

                Text(playerStateModelData.duration.convertDurationToString())
                    .font(.system(size: labelFontSize))
                    .fontWeight(.regular)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
            }
            HStack {
                Spacer()

                Button {
                    playerUI.playbackController?.seek(
                        to: CMTime(seconds: playerStateModelData.progress - 10, preferredTimescale: CMTimeScale(1.0))) { back in
                        if back {
                            print("Back - 10 second")
                        }
                    }
                } label: {
                    Image(systemName: "gobackward.10")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }

                Button {
                    playerStateModelData.isPlaying ? playerUI.playbackController?.pause() : playerUI.playbackController?.play()
                } label: {
                    Image(systemName: playerStateModelData.isPlaying ? "pause" : "play")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                        .padding()
                }

                Button {
                    playerUI.playbackController?.seek(to: CMTime(seconds: playerStateModelData.progress + 10, preferredTimescale: CMTimeScale(1.0))) { next in
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

struct ControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ControlsView(playerUI: PlayerUI())
    }
}
