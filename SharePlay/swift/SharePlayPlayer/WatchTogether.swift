//
//  WatchTogether.swift
//  SharePlayPlayer
//
//  Created by Jeremy Blaker on 6/29/21.
//

import GroupActivities

struct WatchTogether: GroupActivity {
  
    // Specify the activity type to the system.
    static let activityIdentifier = "com.companyname.SharePlayPlayer.watch-movie-together"

    var metadata: GroupActivityMetadata
    var sourceURL: String
    var keySystems: [String:[String:String]]?

}

