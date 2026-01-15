//
//  VideoListItem.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Foundation
import BrightcovePlayerSDK


struct VideoListItem: Identifiable {
    let id: String
    let name: String
    let video: BCOVVideo
}
