//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    
    @State private var selection: Tab = .videos
    @StateObject private var playerModel = PlayerModel()

    enum Tab {
        case videos
        case other
    }

    var body: some View {
        TabView(selection: $selection) {
            VideoListView(playerModel: playerModel)
                .tabItem {
                    if !playerModel.fullscreenEnabled {
                        Label("Videos", systemImage: "list.triangle")
                    }
                }
                .tag(Tab.videos)
            Text("Hello, world!")
                .tabItem {
                    if !playerModel.fullscreenEnabled {
                        Label("Other", systemImage: "info")
                    }
                }
                .tag(Tab.other)
        }
    }
}


// MARK: -

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
