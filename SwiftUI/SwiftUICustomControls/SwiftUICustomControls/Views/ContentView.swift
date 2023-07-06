//
//  ContentView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK
import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var playerStateModelData = PlayerStateModelData()

    var playerUI = PlayerUI()
    var videoModelData = VideoModelData()
    
    @State var cancellables = [AnyCancellable]()

    var body: some View {
        VStack {
            playerUI
                .overlay(ControlsView(playerUI: playerUI), alignment: .bottom)
            .aspectRatio(16/9, contentMode: .fit)
            Spacer()
        }
        .environmentObject(playerStateModelData)
        .onAppear {
            videoModelData.$video
                .receive(on: DispatchQueue.main)
                .dropFirst()
                .sink { video in
                    if let video = video {
                        playerUI.playbackController?.setVideos([video] as NSFastEnumeration)
                    }
                }
                .store(in: &self.cancellables)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Double {
    func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
        if self.isInfinite || self.isNaN { return "" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
        formatter.unitsStyle = style
        return formatter.string(from: self) ?? ""
    }
}
