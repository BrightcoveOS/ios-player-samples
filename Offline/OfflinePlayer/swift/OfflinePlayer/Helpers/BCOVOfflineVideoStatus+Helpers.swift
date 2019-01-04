//
//  BCOVOfflineVideoStatus+Helpers.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK

extension BCOVOfflineVideoStatus {
    
    func downloadPercentString() -> String {
        return String(format: "%0.1f", downloadPercent) + "%"
    }
    
    func downloadStateString(estimatedMegabytes: Double, actualMegabytes: Double, startTime: Double, endTime: Double) -> String {
        
        let currentTime = Date.timeIntervalSinceReferenceDate
        
        switch downloadState {
        case .licensePreloaded:
            return "license preloaded"
        case .stateRequested:
            return "download requested"
        case .stateDownloading:
            let mbps = (CGFloat(estimatedMegabytes) * downloadPercent / 100) / CGFloat(currentTime - startTime)
            // use kbps if the measurement gets too small
            if mbps < 0.5 {
                let kbpsString = String(format: "%0.1f", mbps * 1000)
                return "downloading (\(downloadPercentString()) @ \(kbpsString) KB/s)"
            } else {
                let mbpsString = String(format: "%0.1f", mbps)
                return "downloading (\(downloadPercentString()) @ \(mbpsString) MB/s)"
            }
        case .stateSuspended:
            return "paused (\(downloadPercentString()))"
        case .stateCancelled:
            return "cancelled"
        case .stateCompleted:
            let totalDownloadTime = endTime - startTime
            let mbFloat = CGFloat(actualMegabytes)
            let mbps = (mbFloat * downloadPercent / 100.0) / CGFloat(totalDownloadTime)
            let speedString = mbps < 0.5 ? String(format: "%0.1f%", mbps * 1000) + " KB/s" : String(format: "%0.1f%", mbps) + " MB/s"
            let timeString = totalDownloadTime < 60 ? "\(totalDownloadTime) secs" : "\(totalDownloadTime / 60) secs"
            return "complete (\(speedString) @ \(timeString))"
        case .stateError:
            if error == nil {
                return "unknown error occured"
            }
            let _error = error as NSError
            return "error \(_error.code) (\(error.localizedDescription))"
        case .stateTracksRequested:
            return "tracks download requested"
        case .stateTracksDownloading:
            return "tracks downloading (\(downloadPercentString()))"
        case .stateTracksSuspended:
            return "tracks paused (\(downloadPercentString()))"
        case .stateTracksCancelled:
            return "tracks download cancelled"
        case .stateTracksCompleted:
            return "tracks download complete"
        case .stateTracksError:
            let _error = error as NSError
            return "tracks download error \(_error.code) (\(error.localizedDescription))"
        }
        
    }
    
}
