//
//  BCOVVideo+Helpers.swift
//  BasicIMAPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
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
    
}
