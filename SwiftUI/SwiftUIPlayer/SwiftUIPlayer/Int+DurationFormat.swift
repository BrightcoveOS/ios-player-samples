//
//  Int+DurationFormat.swift
//  SwiftUIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Foundation

extension Int {
    
    public func hmsFrom() -> (Int, Int, Int) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
    public func convertDurationToString() -> String {
        var duration = ""
        let (hour, minute, second) = self.hmsFrom()
        if (hour > 0) {
            duration = self.getHour(hour: hour)
        }
        return "\(duration)\(self.getMinute(minute: minute))\(self.getSecond(second: second))"
    }
    
    private func getHour(hour: Int) -> String {
        var duration = "\(hour):"
        if (hour < 10) {
            duration = "0\(hour):"
        }
        return duration
    }
    
    private func getMinute(minute: Int) -> String {
        if (minute == 0) {
            return "00:"
        }

        if (minute < 10) {
            return "0\(minute):"
        }

        return "\(minute):"
    }
    
    private func getSecond(second: Int) -> String {
        if (second == 0){
            return "00"
        }

        if (second < 10) {
            return "0\(second)"
        }
        return "\(second)"
    }
}
