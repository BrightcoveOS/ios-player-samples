//
//  TimeInterval+Extensions.swift
//  SwiftUIPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import Foundation


extension TimeInterval {

    var stringFromTime: String {
        if isFinite {
            let hours = Int(truncatingRemainder(dividingBy: 86400) / 3600)
            let minutes = Int(truncatingRemainder(dividingBy: 3600) / 60)
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
