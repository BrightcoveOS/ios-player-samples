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
        
        // The video does not have the required VMAP tag on the video, so this code demonstrates
        // how to update a video to set the ad tags on the video.
        // You are responsible for determining where the ad tag should originate from.
        // We advise that if you choose to hard code it into your app, that you provide
        // a mechanism to update it without having to submit an update to your app.
        
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
    
}
