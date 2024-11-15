//
//  BCOVOfflineVideoStatus+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK


extension BCOVOfflineVideoStatus {

    var offlineVideo: BCOVVideo {
        return BCOVOfflineVideoManager.shared().videoObject(fromOfflineVideoToken: offlineVideoToken)
    }

    var infoForDonwloadState: String {
        switch (downloadState) {
            case .stateRequested:
                return "download requested"

            case .stateDownloading:
                let actualMegabytes = UIDevice.current.usedDiskSpace(forVideo: offlineVideo)
                let totalDownloadTime = Date.timeIntervalSinceReferenceDate - downloadStartTime.timeIntervalSinceReferenceDate
                let mbps = (actualMegabytes * downloadPercent / 100) / totalDownloadTime
                let speed = String(format: "%0.2f %@", (mbps < 0.5 ? mbps * 1000 : mbps), (mbps < 0.5 ? "KB/s" : "MB/s"))
                let time = String(format: "%0.1f secs", (totalDownloadTime < 60 ? totalDownloadTime : (totalDownloadTime / 60)))
                return String(format: "downloading (%@ @ %@)\nProgress: %0.2f%%", speed, time, downloadPercent)

            case .stateSuspended:
                return String(format: "paused (%0.2f%%)", downloadPercent)

            case .stateCancelled:
                return "cancelled"

            case .stateCompleted:
                let actualMegabytes = UIDevice.current.usedDiskSpace(forVideo: offlineVideo)
                let totalDownloadTime = downloadEndTime.timeIntervalSinceReferenceDate - downloadStartTime.timeIntervalSinceReferenceDate
                let mbps = actualMegabytes / totalDownloadTime
                let speed = String(format: "%0.2f %@", (mbps < 0.5 ? mbps * 1000 : mbps), (mbps < 0.5 ? "KB/s" : "MB/s"))
                let time = String(format: "%0.1f secs", (totalDownloadTime < 60 ? totalDownloadTime : (totalDownloadTime / 60)))
                return String(format: "complete (%@ @ %@)", speed, time)

            case .stateError:
                if error == nil {
                    return "unknown error occured"
                }

                if let _error = error as NSError? {
                    return "error \(_error.code) (\(error.localizedDescription))"
                }

                return "unknown error"

            case .licensePreloaded:
                return "license preloaded"

            default:
                return "unknown state"
        }
    }
}
