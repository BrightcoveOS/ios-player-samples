//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import SwiftUI


struct ContentView: View {

    @State
    fileprivate var selection = Tab.videos

    @StateObject
    fileprivate var playerModel = PlayerModel()

    enum Tab {
        case videos
    }

    var body: some View {
        TabView(selection: $selection) {
            VideoListView(playerModel: playerModel)
                .tabItem {
                    Label("Videos", systemImage: "list.triangle")
                }
                .tag(Tab.videos)
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
