//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI


struct ContentView: View {

    var body: some View {
        VideoListView()
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
