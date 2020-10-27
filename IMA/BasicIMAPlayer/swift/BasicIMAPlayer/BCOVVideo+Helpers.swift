//
//  BCOVVideo+Helpers.swift
//  BasicIMAPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK
import BrightcoveIMA

extension BCOVVideo {
    
    func updateVideo(withVMAPTag vmapTag: String) -> BCOVVideo {
        
        return update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo = mutableVideo else {
                return
            }
            
            // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
            // the video's properties when using ad rules. This URL returns
            // a VMAP response that is handled by the Google IMA library.
            if var updatedProperties = mutableVideo.properties {
                updatedProperties[kBCOVIMAAdTag] = vmapTag
                mutableVideo.properties = updatedProperties
            }
        }
        
    }
    
    func updateVideo(useAdTagsInCuePoints: Bool) -> BCOVVideo? {
        
        guard let durationNum = self.properties["duration"] as? NSNumber else {
            return nil
        }
        
        let durationMiliSeconds = durationNum.doubleValue
        let midpointSeconds = (durationMiliSeconds / 2) / 1000
        let midpointTime = CMTimeMakeWithSeconds(midpointSeconds, preferredTimescale: 1)
        
        let cuePointPositionTypeAfter = CMTime.positiveInfinity
        
        var preRollProperties = [String:AnyHashable]()
        var midRollProperties = [String:AnyHashable]()
        var postRollProperties = [String:AnyHashable]()
        
        if useAdTagsInCuePoints {
            preRollProperties = [kBCOVIMAAdTag:IMAConfig.VASTAdTagURL_preroll]
            midRollProperties = [kBCOVIMAAdTag:IMAConfig.VASTAdTagURL_midroll]
            postRollProperties = [kBCOVIMAAdTag:IMAConfig.VASTAdTagURL_postroll]
        }
        
        return update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo = mutableVideo else {
                return
            }
            
            mutableVideo.cuePoints = BCOVCuePointCollection(array: [
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd, position: CMTime.zero, properties: preRollProperties)!,
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd, position: midpointTime, properties: midRollProperties)!,
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd, position: cuePointPositionTypeAfter, properties: postRollProperties)!,
            ])
        }
        
    }
    
}
