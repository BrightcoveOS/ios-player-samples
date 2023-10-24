//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    
    @State private var selection: Tab = .videos

    enum Tab {
        case videos
        case other
    }

    var body: some View {
        TabView(selection: $selection) {
            VideoListView()
                .tabItem {
                    Label("Videos", systemImage: "list.triangle")
                }
                .tag(Tab.videos)
            Text("Hello, world!")
                .tabItem {
                    Label("Other", systemImage: "info")
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
