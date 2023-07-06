//
//  VideoListItem.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import BrightcovePlayerSDK

struct VideoListItem: Identifiable {
    var id: String
    var name: String
    var video: BCOVVideo
    @State var uiImage: UIImage?
    
    func duration() -> String {
        guard var duration = video.properties[kBCOVVideoPropertyKeyDuration] as? Int else {
            return ""
        }
        duration = duration / 1000
        return duration.convertDurationToString()
    }
}
