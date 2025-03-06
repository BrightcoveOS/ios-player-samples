//
//  BCOVOfflineVideoStatus+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK


extension BCOVOfflineVideoStatus {

    var offlineVideo: BCOVVideo? {
        guard let offlineVideoToken else {
            return nil
        }
        return BCOVOfflineVideoManager.sharedManager?.videoObject(fromOfflineVideoToken: offlineVideoToken)
    }

    var infoForDonwloadState: String {
        switch (downloadState) {
            case .requested:
                return "download requested"

            case .downloading:
                let actualMegabytes = UIDevice.current.usedDiskSpace(forVideo: offlineVideo!)
                let totalDownloadTime = Date.timeIntervalSinceReferenceDate - (downloadStartTime?.timeIntervalSinceReferenceDate ?? 0)
                let mbps = (actualMegabytes * downloadPercent / 100) / totalDownloadTime
                let speed = String(format: "%0.2f %@", (mbps < 0.5 ? mbps * 1000 : mbps), (mbps < 0.5 ? "KB/s" : "MB/s"))
                let time = String(format: "%0.1f secs", (totalDownloadTime < 60 ? totalDownloadTime : (totalDownloadTime / 60)))
                return String(format: "downloading (%@ @ %@)\nProgress: %0.2f%%", speed, time, downloadPercent)

            case .suspended:
                return String(format: "paused (%0.2f%%)", downloadPercent)

            case .cancelled:
                return "cancelled"

            case .completed:
                let actualMegabytes = UIDevice.current.usedDiskSpace(forVideo: offlineVideo!)
                let totalDownloadTime = (downloadEndTime?.timeIntervalSinceReferenceDate ?? .infinity) - (downloadStartTime?.timeIntervalSinceReferenceDate ?? 0)
                let mbps = actualMegabytes / totalDownloadTime
                let speed = String(format: "%0.2f %@", (mbps < 0.5 ? mbps * 1000 : mbps), (mbps < 0.5 ? "KB/s" : "MB/s"))
                let time = String(format: "%0.1f secs", (totalDownloadTime < 60 ? totalDownloadTime : (totalDownloadTime / 60)))
                return String(format: "complete (%@ @ %@)", speed, time)

            case .error:
                if error == nil {
                    return "unknown error occured"
                }

                if let _error = error as NSError? {
                    return "error \(_error.code) (\(_error.localizedDescription))"
                }

                return "unknown error"

            case .licensePreloaded:
                return "license preloaded"

            default:
                return "unknown state"
        }
    }
}
