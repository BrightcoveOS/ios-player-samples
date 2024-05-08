//
//  Double+Extensions.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import CoreMedia
import UIKit


extension Double {

    var asCMTime: CMTime {
        return CMTime(seconds: self,
                      preferredTimescale: CMTimeScale(60))
    }
}
