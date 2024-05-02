//
//  TimeInterval+Extensions.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit


extension TimeInterval {

    var stringFromTime: String {
        if isFinite {
            let hours = Int(truncatingRemainder(dividingBy: 86_400) / 3_600)
            let minutes = Int(truncatingRemainder(dividingBy: 3_600) / 60)
            let seconds = Int(truncatingRemainder(dividingBy: 60))
            if hours > 0 {
                return String(format: "%i:%02i:%02i", hours, minutes, seconds)
            } else {
                return String(format: "%02i:%02i", minutes, seconds)
            }
        } else {
            return ""
        }
    }
}
