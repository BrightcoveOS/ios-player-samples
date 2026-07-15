//
//  DownloadManager.swift
//  OfflinePlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


struct VideoDownload {
    let video: BCOVVideo
    let parameters: [String: Any]
}


final class DownloadManager: NSObject {

    static let shared = DownloadManager()

    class var downloadParameters: [String: Any] {
        // Get base license parameters
        var downloadParameters = DownloadManager.licenseParameters

        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow),
              let rootViewController = window.rootViewController as? UITabBarController,
              let settingsViewController = rootViewController.settingsViewController else {
            return downloadParameters
        }

        // Add bitrate parameter for the primary download
        let bitrate = settingsViewController.bitrate

        downloadParameters[BCOVOfflineVideoManager.RequestedBitrateKey] = bitrate

        return downloadParameters
    }

    class var licenseParameters: [String: Any] {
        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow),
              let rootViewController = window.rootViewController as? UITabBarController,
              let settingsViewController = rootViewController.settingsViewController else {
            return .init()
        }

        var licenseParameters: [String: Any] = .init()

        // Generate the license parameters based on the Settings tab
        let isPurchaseLicense = settingsViewController.purchaseLicenseType
        // License details are only needed for FairPlay-protected videos.
        // It's harmless to add it for non-FairPlay videos too.

        if isPurchaseLicense {
            licenseParameters[BCOVFairPlayLicense.PurchaseKey] = true
        } else {
            let rentalDuration = settingsViewController.rentalDuration
            let playDuration = settingsViewController.playDuration

            licenseParameters[BCOVFairPlayLicense.RentalDurationKey] = rentalDuration
            licenseParameters[BCOVFairPlayLicense.PlayDurationKey] = playDuration
        }

        return licenseParameters
    }

    // The download queue.
    // Videos go into the preload queue first.
    // When all preloads are done, videos move to the download queue.
    fileprivate var videoPreloadQueue: [VideoDownload] = .init()
    fileprivate var videoDownloadQueue: [VideoDownload] = .init()

    // Serializes all access to `videoPreloadQueue` and `videoDownloadQueue`,
    // which are read and mutated from both the main queue and a background queue.
    private let queueAccess = DispatchQueue(label: "com.brightcove.offlineplayer.download-queue")

    func doDownload(forVideo video: BCOVVideo) {
        if videoAlreadyProcessing(video) {
            return
        }

        let videoDownload = VideoDownload(video: video,
                                          parameters: DownloadManager.downloadParameters)

        queueAccess.sync {
            videoPreloadQueue.append(videoDownload)
        }

        DispatchQueue.main.async { [self] in
            runPreloadVideoQueue()
        }
    }

    fileprivate func videoAlreadyProcessing(_ video: BCOVVideo) -> Bool {
        // First check to see if the video is in a preload queue
        // videoPreloadQueue is an array of NSDictionary objects,
        // with a BCOVVideo under each "video" key.
        let preloadQueue = queueAccess.sync { videoPreloadQueue }
        for videoDict in preloadQueue {
            if videoDict.video.matches(with: video) {
                UIAlertController.showWith(title: "Video Already in Preload Queue",
                                           message: "The video \(video.localizedName ?? "unknown") is already queued to be preloaded")

                return true
            }
        }

        // First check to see if the video is in a download queue
        // videoDownloadQueue is an array of BCOVVideo objects
        let downloadQueue = queueAccess.sync { videoDownloadQueue }
        for videoDict in downloadQueue {
            if videoDict.video.matches(with: video) {
                UIAlertController.showWith(title: "Video Already in Download Queue",
                                           message: "The video \(video.localizedName ?? "unknown") is already queued to be downloaded")

                return true
            }
        }

        // Next check to see if the video has already been downloaded
        // or is in the process of downloading
        guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
            return false
        }

        let offlineVideoTokens = offlineManager.offlineVideoTokens

        for offlineVideoToken in offlineVideoTokens {
            guard let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: offlineVideoToken) else {
                continue
            }

            if offlineVideo.matches(with: video) {
                // If the status is error, alert the user and allow them to retry the download
                if let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: offlineVideoToken),
                   offlineVideoStatus.downloadState == .error ||
                    offlineVideoStatus.downloadState == .cancelled {
                    UIAlertController.showWith(title: "Video Failed to Download",
                                               message: "The video \(video.localizedName ?? "unknown") previously failed to download or was cancelled, would you like to try again?",
                                               actionTitle: "Retry",
                                               cancelTitle: "Cancel") {

                        offlineManager.deleteOfflineVideo(offlineVideoToken)
                        DownloadManager.shared.doDownload(forVideo: video)
                    }

                    return true
                }

                UIAlertController.showWith(title: "Video Already Downloaded",
                                           message: "The video \(video.localizedName ?? "unknown") is already downloaded (or downloading)")
                return true
            }
        }

        return false
    }

    fileprivate func runPreloadVideoQueue() {
        let videoDownload: VideoDownload? = queueAccess.sync { () -> VideoDownload? in
            guard let videoDownload = videoPreloadQueue.first else {
                return nil
            }

            if let indexOfVideo = videoPreloadQueue.firstIndex(where: { $0.video.matches(with: videoDownload.video) }) {
                videoPreloadQueue.remove(at: indexOfVideo)
            }

            return videoDownload
        }

        guard let videoDownload else {
            DispatchQueue.global(qos: .background).async { [self] in
                downloadVideoFromQueue()
            }

            return
        }

        // Preloading only applies to FairPlay-protected videos.
        // If there's no FairPlay involved, the video is moved on
        // to the video download queue.
        if !videoDownload.video.usesFairPlay {
            queueAccess.sync {
                videoDownloadQueue.append(videoDownload)
            }

            DispatchQueue.main.async { [self] in
                runPreloadVideoQueue()

                NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                                object: videoDownload.video)
            }
        } else {
            guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
                return
            }

            offlineManager.preloadFairPlayLicense(videoDownload.video,
                                                  parameters: videoDownload.parameters) {
                (offlineVideoToken: String?, error: Error?) in

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    if let error {
                        // Report any errors
                        UIAlertController.showWith(title: "Video Preload Error\n(\(videoDownload.video.localizedName ?? "unknown"))",
                                                   message: error.localizedDescription)
                    } else {
                        if let offlineVideoToken {
                            print("Preloaded \(offlineVideoToken)")
                        }

                        queueAccess.sync {
                            self.videoDownloadQueue.append(videoDownload)
                        }
                    }

                    runPreloadVideoQueue()

                    NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                                    object: videoDownload.video)
                }
            }
        }
    }

    fileprivate func downloadVideoFromQueue() {
        let videoDownload: VideoDownload? = queueAccess.sync { () -> VideoDownload? in
            guard let videoDownload = videoDownloadQueue.first else {
                return nil
            }

            if let indexOfVideo = videoDownloadQueue.firstIndex(where: { $0.video.matches(with: videoDownload.video) }) {
                videoDownloadQueue.remove(at: indexOfVideo)
            }

            return videoDownload
        }

        guard let videoDownload else {
            return
        }

        guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
            return
        }

        // Display all available bitrates
        offlineManager.variantBitrates(forVideo: videoDownload.video) {
            (bitrates: [Int]?, error: Error?) in

            print("Variant Bitrates for video: \(videoDownload.video.localizedName ?? "unknown")")

            if let bitrates {
                for bitrate in bitrates {
                    print("\(bitrate)")
                }
            }
        }

        var urlAsset: AVURLAsset?
        do {
            urlAsset = try offlineManager.urlAsset(forVideo: videoDownload.video)
        } catch {}

        if let urlAsset {
            // HLSe (AES-128) streams are not supported for offline playback
            if urlAsset.url.absoluteString.contains("aes128") {
                UIAlertController.showWith(title: "Content Not Supported",
                                           message: "Offline playback is not supported for HLSe content.")
                return
            }
        }

        // If mediaSelections is `nil` the SDK will default to the AVURLAsset's `preferredMediaSelection`
        var mediaSelections = [AVMediaSelection]()

        if let urlAsset {
            mediaSelections = urlAsset.allMediaSelections

            if let legibleMediaSelectionGroup = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .legible),
               let audibleMediaSelectionGroup = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .audible) {

                var counter = 0
                for selection in mediaSelections {
                    let legibleMediaSelectionOption = selection.selectedMediaOption(in: legibleMediaSelectionGroup)
                    let audibleMediaSelectionOption = selection.selectedMediaOption(in: audibleMediaSelectionGroup)

                    let legibleName = legibleMediaSelectionOption?.displayName ?? "nil"
                    let audibleName = audibleMediaSelectionOption?.displayName ?? "nil"

                    print("AVMediaSelection option \(counter) | legible display name: \(legibleName)")
                    print("AVMediaSelection option \(counter) | audible display name: \(audibleName)")
                    counter += 1
                }
            }
        }

        offlineManager.requestVideoDownload(videoDownload.video,
                                            mediaSelections: mediaSelections,
                                            parameters: videoDownload.parameters) {
            (offlineVideoToken: String?, error: Error?) in

            DispatchQueue.main.async {
                if let error {
                    // Report any errors
                    UIAlertController.showWith(title: "Video Download Error",
                                               message: error.localizedDescription)
                }

                NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                                object: videoDownload.video)
            }
        }
    }

    fileprivate class func mediaSelectionDescription(from mediaSelection: AVMediaSelection,
                                                     with urlAsset: AVURLAsset) -> String {
        // Return a string description of the specified Media Selection.
        guard let legibleMSG = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .legible),
              let audibleMSG = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .audible) else {
            return "MediaSelection(n/a)"
        }

        let legibleDisplayName = mediaSelection.selectedMediaOption(in: legibleMSG)?.displayName ?? "-"
        let audibleDisplayName = mediaSelection.selectedMediaOption(in: audibleMSG)?.displayName ?? "-"

        return "MediaSelection(obj:\(mediaSelection), legible:\(legibleDisplayName), audible:\(audibleDisplayName))"
    }
}


// MARK: - BCOVOfflineVideoManagerDelegate

extension DownloadManager: BCOVOfflineVideoManagerDelegate {

    func didCreateSharedBackgroundSesssionConfiguration(_ backgroundSessionConfiguration: URLSessionConfiguration) {
        // Helps prevent downloads from appearing to sometimes stall
        backgroundSessionConfiguration.isDiscretionary = false
    }

    func offlineVideoToken(_ offlineVideoToken: BCOVOfflineVideoToken, aggregateDownloadTask: AVAggregateAssetDownloadTask, didProgressTo progressPercent: TimeInterval, forMediaSelection mediaSelection: AVMediaSelection) {

        // The specific requested media selected option related to this
        // offline video token has progressed to the specified percent
        guard let offlineManager = BCOVOfflineVideoManager.sharedManager,
              let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: offlineVideoToken) else {

            NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                            object: nil)
            return
        }

        print("aggregateDownloadTask:didProgressTo: \(String(format: "%0.2f", progressPercent)) for token: \(offlineVideoToken)")

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: offlineVideo)
    }

    func offlineVideoToken(_ offlineVideoToken: BCOVOfflineVideoToken, didFinishMediaSelectionDownload mediaSelection: AVMediaSelection) {

        // The specific requested media selected option related to this
        // offline video token has completed downloading
        guard let offlineManager = BCOVOfflineVideoManager.sharedManager,
              let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: offlineVideoToken), let aggregateDownloadTask = offlineVideoStatus.aggregateDownloadTask else {
            return
        }

        let urlAsset = aggregateDownloadTask.urlAsset
        let mediaSelectionDescription = DownloadManager.mediaSelectionDescription(from: mediaSelection,
                                                                                  with: urlAsset)

        print("didFinishMediaSelectionDownload: \(mediaSelectionDescription) for token: \(offlineVideoToken)")
    }

    func offlineVideoToken(_ offlineVideoToken: BCOVOfflineVideoToken, didFinishDownloadWithError error: (any Error)?) {

        // The video has completed downloading
        if let error {
            print("Download finished with error: \(error.localizedDescription)")
        }

        guard let offlineManager = BCOVOfflineVideoManager.sharedManager,
              let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: offlineVideoToken) else {

            NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                            object: nil)

            return
        }

        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: offlineVideo)
    }

    func offlineVideoStorageDidChange() {
        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus,
                                        object: nil)
    }
}
