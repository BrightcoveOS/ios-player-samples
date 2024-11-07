//
//  BCOVPulseVideoItem.swift
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Foundation


final class BCOVPulseVideoItem: NSObject {

    fileprivate(set) var title: String?
    fileprivate(set) var category: String?
    fileprivate(set) var tags: Array<String>?
    fileprivate(set) var midrollPositions: Array<NSNumber>?
    fileprivate(set) var extendSession: Bool? = false

    static func staticInit(dictionary: [String: Any]) -> BCOVPulseVideoItem {
        let videoItem = BCOVPulseVideoItem()

        videoItem.title = dictionary["content-title"] as? String ?? ""
        videoItem.category = dictionary["category"] as? String
        videoItem.tags = dictionary["tags"] as? Array<String>
        videoItem.midrollPositions = dictionary["midroll-positions"] as? Array<NSNumber>
        videoItem.extendSession = dictionary["extend-session"] as? Bool

        return videoItem
    }
}
