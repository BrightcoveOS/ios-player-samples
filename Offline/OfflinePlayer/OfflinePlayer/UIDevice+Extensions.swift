//
//  UIDevice+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


extension UIDevice {

    var isSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }

    var freeDiskSpace: String {
        return GBFormatter(freeDiskSpaceInBytes)
    }

    var totalDiskSpace: String {
        return GBFormatter(totalDiskSpaceInBytes)
    }

    func usedDiskSpaceWithUnits(forVideo video: BCOVVideo) -> String {
        guard let videoFilePath = video.properties[BCOVOfflineVideo.FilePathPropertyKey] as? String else {
            return Formatter(.zero)
        }

        return Formatter(getDiskSpace(forFolderPath: videoFilePath))
    }

    func usedDiskSpace(forVideo video: BCOVVideo) -> Double {
        guard let videoFilePath = video.properties[BCOVOfflineVideo.FilePathPropertyKey] as? String,
              let usedSpace = Double(Formatter(getDiskSpace(forFolderPath: videoFilePath),
                                               includeUnit: false)) else {
            return .zero
        }

        return usedSpace
    }

    fileprivate func Formatter(_ bytes: Int64,
                               includeUnit: Bool = true) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        formatter.includesUnit = includeUnit
        formatter.includesCount = true
        formatter.zeroPadsFractionDigits = true

        return formatter.string(fromByteCount: bytes) as String
    }

    fileprivate func GBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useGB
        formatter.countStyle = .file
        formatter.includesUnit = false
        formatter.includesCount = true
        formatter.zeroPadsFractionDigits = true

        return formatter.string(fromByteCount: bytes) as String
    }

    fileprivate func getDiskSpace(forFolderPath folderPath: String) -> Int64 {
        var directorySize = Int64.zero
        do {
            let filesArray = try FileManager.default.subpathsOfDirectory(atPath: folderPath)

            for fileName in filesArray {
                let path = folderPath + "/" + fileName
                let fileDictionary = try FileManager.default.attributesOfItem(atPath: path)
                if let filesize = fileDictionary[.size] as? NSNumber {
                    directorySize = directorySize + filesize.int64Value
                }
            }
        } catch {
            print("\(error.localizedDescription)")
        }

        return directorySize
    }

    fileprivate var freeDiskSpaceInBytes: Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber else {
            return 0
        }

        return freeSpace.int64Value
    }

    fileprivate var totalDiskSpaceInBytes: Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSpace = systemAttributes[.systemSize] as? NSNumber else {
            return 0
        }

        return totalSpace.int64Value
    }
}
