//
//  WatchTogether.swift
//  SharePlayPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import GroupActivities

struct WatchTogether: GroupActivity {

    // Specify the activity type to the system.
    static let activityIdentifier = "com.brightcove.player.samples.SharePlayPlayer.watch-movie-together"

    var metadata: GroupActivityMetadata
    var sourceURL: String
    var keySystems: [String: [String: String]]?

}
