//
//  Double+Extensions.swift
//  CustomControls
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import CoreMedia
import UIKit


extension Double {

    var asCMTime: CMTime {
        CMTime(seconds: self,
               preferredTimescale: CMTimeScale(60))
    }
}
