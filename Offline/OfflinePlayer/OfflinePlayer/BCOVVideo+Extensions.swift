//
//  BCOVVideo+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK


extension BCOVVideo {

    var accountId: String? {
        return properties[BCOVVideo.PropertyKeyAccountId] as? String
    }

    var videoId: String? {
        return properties[BCOVVideo.PropertyKeyId] as? String
    }

    var localizedName: String? {
        return self.localizedName(forLocale: nil)
    }

    var localizedShortDescription: String? {
        return self.localizedShortDescription(forLocale: nil)
    }

    var duration: String {
        guard let durationNumber = properties[BCOVVideo.PropertyKeyDuration] as? NSNumber else {
            return ""
        }

        let totalSeconds = durationNumber.doubleValue / 1000
        let hours = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }

    var offlineVideoToken: String? {
        return properties[kBCOVOfflineVideoTokenPropertyKey] as? String
    }

    var license: String {
        if !usesFairPlay {
            return "clear"
        }

        if let purchase = properties[kBCOVFairPlayLicensePurchaseKey] as? NSNumber,
           purchase.boolValue {
            return "purchase"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        if let absoluteExpirationNumber = properties[kBCOVOfflineVideoLicenseAbsoluteExpirationTimePropertyKey] as? NSNumber {
            let absoluteExpirationTime = absoluteExpirationNumber.doubleValue
            var expirationDate = Date(timeIntervalSinceReferenceDate: absoluteExpirationTime)
            if let playDurationNumber = properties[kBCOVFairPlayLicensePlayDurationKey] as? NSNumber,
               let initialPlayNumber = properties[kBCOVOfflineVideoInitialPlaybackTimeKey] as? NSNumber,
               playDurationNumber.intValue > 0 {
                let initialPlayTime = TimeInterval(initialPlayNumber.intValue)
                let initialPlayDate = Date(timeIntervalSinceReferenceDate: initialPlayTime)
                let playDurationExpirationDate = initialPlayDate.addingTimeInterval(TimeInterval(playDurationNumber.intValue))
                if absoluteExpirationNumber.doubleValue > playDurationExpirationDate.timeIntervalSinceReferenceDate {
                    expirationDate = playDurationExpirationDate
                }
            }
            return "rental (expires \(dateFormatter.string(from: expirationDate)))"
        } else if let rentalDurationNumber = properties[kBCOVFairPlayLicenseRentalDurationKey] as? NSNumber,
                  let startTimeNumber = properties[kBCOVOfflineVideoDownloadStartTimePropertyKey] as? NSNumber {
            let rentalDuration = rentalDurationNumber.doubleValue
            let startTime = startTimeNumber.doubleValue
            let startDate = Date(timeIntervalSinceReferenceDate: startTime)
            let expirationDate = startDate.addingTimeInterval(rentalDuration)
            return "rental (expires \(dateFormatter.string(from: expirationDate)))"
        }

        return "unknown license"
    }

    func matches(with video: BCOVVideo) -> Bool {
        // Returns true if the two video objects reference the same video asset.
        // Specifically, they have the same account and same video Id.
        guard let v1Account = accountId,
              let v1Id = videoId,
              let v2Account = video.accountId,
              let v2Id = video.videoId else {
            return false
        }

        return (v1Account == v2Account) && (v1Id == v2Id)
    }
}
