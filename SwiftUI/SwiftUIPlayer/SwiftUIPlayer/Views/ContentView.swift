//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

let bcovPlayerUI = BCOVPlayerUI()
let applePlayerUI = ApplePlayerUI()

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
