//
//  Config.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import Foundation

enum Config {
    static let accountID = "5434391461001"
    static let policyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"

    static let demoVideos: [DemoVideo] = [
        DemoVideo(id: "6140448705001", title: "Getting Started with the Brightcove Native SDKs"),
        DemoVideo(id: "5702141808001", title: "Big Buck Bunny"),
    ]

    /// Pre-roll, mid-roll, and post-roll cuepoint VAST tag.
    /// See https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags
    static let vastAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="

    /// VMAP ad rules tag (server-defined ad break schedule).
    static let vmapAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator="

    /// OMID-enabled VAST tag: a pre-roll that exercises Open Measurement
    /// SDK reporting for IAB-compliant viewability tracking.
    static let omidVASTAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?iu=/124319096/external/omid_google_samples&env=vp&gdfp_req=1&output=vast&sz=640x480&description_url=http%3A%2F%2Ftest_site.com%2Fhomepage&tfcd=0&npa=0&vpmute=0&vpa=0&vad_format=linear&url=http%3A%2F%2Ftest_site.com&vpos=preroll&unviewed_position_start=1&correlator="
}

struct DemoVideo: Identifiable, Hashable {
    let id: String
    let title: String
}

enum AdMode: String, CaseIterable, Identifiable {
    case vmap
    case vast
    case vastOM

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vmap: "VMAP"
        case .vast: "VAST"
        case .vastOM: "VAST+OMID"
        }
    }
}
