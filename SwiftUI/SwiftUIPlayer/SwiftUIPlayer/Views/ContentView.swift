//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

var playerUI = PlayerUI()

struct ContentView: View {
    var body: some View {
        VideoList()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
