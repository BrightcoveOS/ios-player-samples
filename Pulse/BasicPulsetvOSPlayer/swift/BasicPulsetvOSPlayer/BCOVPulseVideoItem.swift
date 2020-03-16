//
//  BCOVPulseVideoItem.swift
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 3/13/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import UIKit

class BCOVPulseVideoItem: NSObject
{
    var title: String? = ""
    var category: String? = ""
    var tags: Array<String>? = []
    var flags: Array<String>? = []
    var midrollPositions: Array<NSNumber>? = []
    
    static func staticInit(dictionary: [String : Any]) -> BCOVPulseVideoItem
    {
        let videoItem = BCOVPulseVideoItem()
        
        videoItem.title = dictionary["content-title"] as? String
        videoItem.category = dictionary["category"] as? String
        videoItem.tags = dictionary["tags"] as? Array<String>
        videoItem.flags = dictionary["flags"] as? Array<String>
        videoItem.midrollPositions = dictionary["midroll-positions"] as? Array<NSNumber>

        return videoItem
    }
}
