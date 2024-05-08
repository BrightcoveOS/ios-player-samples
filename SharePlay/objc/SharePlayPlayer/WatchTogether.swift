//
//  WatchTogether.swift
//  SharePlayPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import GroupActivities

struct WatchTogether: GroupActivity {

    // Specify the activity type to the system.
    static let activityIdentifier = "com.companyname.SharePlayPlayer.watch-movie-together"

    var metadata: GroupActivityMetadata
    var sourceURL: String
    var keySystems: [String: [String: String]]?
    
}
