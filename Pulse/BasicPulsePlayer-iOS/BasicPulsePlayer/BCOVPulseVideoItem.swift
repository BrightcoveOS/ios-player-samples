//
//  BCOVPulseVideoItem.swift
//  BasicPulsePlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import Foundation


final class BCOVPulseVideoItem: NSObject {

    fileprivate(set) var title: String?
    fileprivate(set) var category: String?
    fileprivate(set) var tags: [String]?
    fileprivate(set) var midrollPositions: [NSNumber]?
    fileprivate(set) var extendSession: Bool?

    static func staticInit(dictionary: [String: Any]) -> BCOVPulseVideoItem {
        let videoItem = BCOVPulseVideoItem()

        videoItem.title = dictionary["content-title"] as? String ?? ""
        videoItem.category = dictionary["category"] as? String
        videoItem.tags = dictionary["tags"] as? [String]
        videoItem.midrollPositions = dictionary["midroll-positions"] as? [NSNumber]
        videoItem.extendSession = dictionary["extend-session"] as? Bool

        return videoItem
    }
}
