//
//  ContentView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.

import SwiftUI


struct ContentView: View {

    var body: some View {
        VStack {
            PlayerUIView()
                .padding(.top, 8)
            Spacer()
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
