//
//  VideoList.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct VideoList: View {
    @StateObject private var modelData = ModelData()
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    Text("Select Control Type:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Picker("Control Type", selection: $modelData.controlType) {
                        ForEach(ModelData.ControlType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                List(modelData.videoListItems) { listItem in
                    NavigationLink {
                        VideoDetail(videoListItem: listItem)
                    } label: {
                        VideoListRow(listItem: listItem)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Videos")
        }
        .navigationViewStyle(.stack)
        .environmentObject(modelData)
    }
}

struct VideoList_Previews: PreviewProvider {
    static var previews: some View {
        VideoList()
    }
}
