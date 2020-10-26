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
            // the video's properties when using server side ad rules. This URL returns
            // a VMAP response that is handled by the Google IMA library.
            if var updatedProperties = mutableVideo.properties {
                updatedProperties[kBCOVIMAAdTag] = vmapTag
                mutableVideo.properties = updatedProperties
            }
        }
        
    }
    
    func updateVideo(withVASTTag vastTag: String) -> BCOVVideo? {
        
        guard let durationNum = self.properties["duration"] as? NSNumber else {
            return nil
        }
        
        let durationMiliSeconds = durationNum.doubleValue
        let midpointSeconds = (durationMiliSeconds / 2) / 1000
        let midpointTime = CMTimeMakeWithSeconds(midpointSeconds, preferredTimescale: 1)
        
        let cuePointPositionTypeAfter = CMTime.positiveInfinity
        
        return update { (mutableVideo: BCOVMutableVideo?) in
            guard let mutableVideo = mutableVideo else {
                return
            }
            
            mutableVideo.cuePoints = BCOVCuePointCollection(array: [
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd, position: CMTime.zero, properties: [kBCOVIMAAdTag:vastTag])!,
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd, position: midpointTime, properties: [kBCOVIMAAdTag:vastTag])!,
                BCOVCuePoint(type: kBCOVIMACuePointTypeAd, position: cuePointPositionTypeAfter, properties: [kBCOVIMAAdTag:vastTag])!,
            ])
        }
        
    }
    
}
