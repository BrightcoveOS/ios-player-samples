//
//  VideoListItem.swift
//  SwiftUIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import Foundation
import BrightcovePlayerSDK


struct VideoListItem: Identifiable {
    let id: String
    let name: String
    let video: BCOVVideo
}
