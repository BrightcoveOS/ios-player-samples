//
//  BCOVVideo+Helpers.swift
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import BrightcoveIMA


// See https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags for other sample VMAP and VAST ad tag URLs
let kVASTAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
let kVASTOMAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?iu=/124319096/external/omid_google_samples&env=vp&gdfp_req=1&output=vast&sz=640x480&description_url=http%3A%2F%2Ftest_site.com%2Fhomepage&tfcd=0&npa=0&vpmute=0&vpa=0&vad_format=linear&url=http%3A%2F%2Ftest_site.com&vpos=preroll&unviewed_position_start=1&correlator="
let kVMAPAdTagURL = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator="


extension BCOVVideo {

    func updateVideo(useAdTagsInCuePoints: Bool) -> BCOVVideo {
        guard let durationNum = properties["duration"] as? NSNumber else {
            return self
        }

        let durationMiliSeconds = durationNum.doubleValue
        let midpointSeconds = (durationMiliSeconds / 2) / 1000
        let midpointTime = CMTimeMakeWithSeconds(midpointSeconds, preferredTimescale: 1)

        let cuePointPositionTypeAfter = CMTime.positiveInfinity

        let properties = useAdTagsInCuePoints ? [kBCOVIMAAdTag: kVASTAdTagURL] : [:]

        return update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo else {
                return
            }

            mutableVideo.cuePoints = BCOVCuePointCollection(array: [
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd,
                             position: .zero,
                             properties: properties)!,
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd,
                             position: midpointTime,
                             properties: properties)!,
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd,
                             position: cuePointPositionTypeAfter,
                             properties: properties)!,
            ])
        }
    }
    
    func updateVideo(withVASTTag vastTag: String) -> BCOVVideo {
        return update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo else {
                return
            }

            let preRollProperties = [kBCOVIMAAdTag: vastTag]

            mutableVideo.cuePoints = BCOVCuePointCollection(array: [
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd,
                             position: CMTime.zero,
                             properties: preRollProperties)!,
            ])
        }
    }

    func updateVideo(withVMAPTag vmapTag: String) -> BCOVVideo {
        return update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo else {
                return
            }

            // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
            // the video's properties when using ad rules. This URL returns
            // a VMAP response that is handled by the Google IMA library.
            var updatedProperties = mutableVideo.properties
            updatedProperties[kBCOVIMAAdTag] = vmapTag
            mutableVideo.properties = updatedProperties
        }
    }
}
