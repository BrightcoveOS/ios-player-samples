//
//  DownloadManager.swift
//  OfflinePlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

struct VideoDownload {
    let video: BCOVVideo
    let paramaters: [String:Any]
}

class DownloadManager: NSObject {
    
    // The download queue.
    // Videos go into the preload queue first.
    // When all preloads are done, videos move to the download queue.
    private var videoPreloadQueue: [VideoDownload] = []
    private var videoDownloadQueue: [VideoDownload] = []
    private var downloadInProgress = false
    
    weak var delegate: ReloadDelegate?
    
    static var shared = DownloadManager()
    
    func doDownload(forVideo video: BCOVVideo) {
        
        if videoAlreadyProcessing(video) {
            return
        }
        
        let downloadParamaters = DownloadManager.generateDownloadParameters()
        
        let videoDownload = VideoDownload(video: video, paramaters: downloadParamaters)
        
        videoPreloadQueue.append(videoDownload)
        
        runPreloadVideoQueue()
        
    }
    
    private func languagesArrayForAlternativeRenditions(attributesDictArray: [[AnyHashable:Any]]?) -> [String] {
     
        // We want to download all subtitle/audio tracks
        guard let attributesDictArray = attributesDictArray else {
            return []
        }
        
        //print("Alternative Rendition Attributes Dictionaries: \(attributesDictArray)")
        
        // Collect all the available subtitle languages in a set to avoid duplicates
        var languageSet = Set<String>()
        for attributeDict in attributesDictArray {
            if let typeString = attributeDict["TYPE"] as? String, let langString = attributeDict["LANGUAGE"] as? String {
                if typeString == "SUBTITLES" {
                    languageSet.insert(langString)
                }
            }
        }
        
        let languagesArray = Array(languageSet)
        // For debugging: display the languages we found
        var languagesString = String()
        var first = true
        for languageString in languagesArray {
            // Add comma before each entry after the first
            if first {
                first = false
            } else {
                languagesString = languagesString + ", "
            }
            
            languagesString = languagesString + languageString
        }
        
        print("Languages to download: \(languagesString)")
        
        return languagesArray
    }
        
    private func videoAlreadyProcessing(_ video: BCOVVideo) -> Bool {
        // First check to see if the video is in a preload queue
        // videoPreloadQueue is an array of NSDictionary objects,
        // with a BCOVVideo under each "video" key.
        
        for videoDict in videoPreloadQueue {
            
            if videoDict.video.matches(offlineVideo: video) {
                if let videoName = localizedNameForLocale(video, nil) {
                    UIAlertController.show(withTitle: "Video Already in Preload Queue", andMessage: "The video \(videoName) is already queued to be preloaded")
                }
                return true
            }
            
        }
        
        // First check to see if the video is in a download queue
        // videoDownloadQueue is an array of BCOVVideo objects
        for videoDict in videoDownloadQueue {
         
            if videoDict.video.matches(offlineVideo: video) {
                if let videoName = localizedNameForLocale(video, nil) {
                    UIAlertController.show(withTitle: "Video Already in Download Queue", andMessage: "The video \(videoName) is already queued to be downloaded")
                }
                return true
            }
            
        }
        
        // Next check to see if the video has already been downloaded
        // or is in the process of downloading
        guard let offlineVideoTokens = BCOVOfflineVideoManager.shared()?.offlineVideoTokens else {
            return false
        }
        
        for offlineVideoToken in offlineVideoTokens {
            
            guard let testVideo = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineVideoToken) else {
                continue
            }
            
            if testVideo.matches(offlineVideo: video) {
                
                let videoName = localizedNameForLocale(video, nil) ?? ""
                
                // If the status is error, alert the user and allow them to retry the download
                if let downloadStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: offlineVideoToken) {
                    if downloadStatus.downloadState == .stateError {
                        
                        UIAlertController.show(withTitle: "Video Failed to Download", message: "The video \(videoName) previously failed to download, would you like to try again?", actionTitle: "Retry", cancelTitle: "Cancel") {
                            
                            print("Deleting previous download for video and attempting again.")
                            
                            BCOVOfflineVideoManager.shared()?.deleteOfflineVideo(offlineVideoToken)
                            
                            DownloadManager.shared.doDownload(forVideo: video)
                            
                        }

                        return true
                    }
                }
                
                UIAlertController.show(withTitle: "Video Already Downloaded", andMessage: "The video \(videoName) is already downloaded (or downloading)")
                return true
                
            }
            
        }
        
        return false
    }
    
    private func runPreloadVideoQueue() {
        
        guard let videoDownload = videoPreloadQueue.first else {
            downloadVideoFromQueue()
            return
        }
        
        let video = videoDownload.video
        
        if let indexOfVideo = videoPreloadQueue.firstIndex(where: { $0.video.matches(offlineVideo: video) }) {
            videoPreloadQueue.remove(at: indexOfVideo)
        }
        
        // Preloading only applies to FairPlay-protected videos.
        // If there's no FairPlay involved, the video is moved on
        // to the video download queue.
        
        if !video.usesFairPlay {
            if let videoName = localizedNameForLocale(video, nil) as? String {
                print("Video \"\(videoName)\" does not use FairPlay; preloading not necessary")
            }
            
            videoDownloadQueue.append(videoDownload)
            
            delegate?.reloadRow(forVideo: video)
            runPreloadVideoQueue()
        } else {
            
            BCOVOfflineVideoManager.shared()?.preloadFairPlayLicense(video, parameters: videoDownload.paramaters, completion: { [weak self] (offlineVideoToken: String?, error: Error?) in
                
                DispatchQueue.main.async {
                    
                    if let error = error {
                        
                        var name = localizedNameForLocale(video, nil) ?? "unknown"
                        if let offlineVideo = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineVideoToken), let offlineName = localizedNameForLocale(offlineVideo, nil) {
                            name = offlineName
                        }
                        
                        // Report any errors
                        UIAlertController.show(withTitle: "Video Preload Error (\(name))", andMessage: error.localizedDescription)
                        
                    } else {
                        if let offlineVideoToken = offlineVideoToken {
                            print("Preloaded \(offlineVideoToken)")
                        }
                        
                        self?.videoDownloadQueue.append(videoDownload)
                        self?.delegate?.reloadRow(forVideo: video)
                    }
                    
                    self?.runPreloadVideoQueue()
                    
                }
                
            })
            
        }
        
    }
    
    private func downloadVideoFromQueue() {
        
        // If we're already downoading, this will be called automatically
        // when the download is done
        // Only needed for pre-iOS 11.4 only which can only handle
        // One download at a time
        if #available(iOS 11.4, *)
        {}
        else if downloadInProgress {
            return
        }
        
        guard let videoDownload = videoDownloadQueue.first else {
            return
        }
        
        let video = videoDownload.video
        
        if let indexOfVideo = videoDownloadQueue.firstIndex(where: { $0.video.matches(offlineVideo: video) }) {
            videoDownloadQueue.remove(at: indexOfVideo)
        }
        
        downloadInProgress = true
        
        // Display all available bitrates
        BCOVOfflineVideoManager.shared()?.variantBitrates(for: video, completion: { (bitrates: [NSNumber]?, error: Error?) in
            
            if let name = localizedNameForLocale(video, nil) as? String {
                print("Variant Bitrates for video: \(name)")
            }
            
            if let bitrates = bitrates {
                for bitrate in bitrates {
                    print("\(bitrate.intValue)")
                }
            }
            
        })
    
        var avURLAsset: AVURLAsset?
        do {
            avURLAsset = try BCOVOfflineVideoManager.shared()?.urlAsset(for: video)
        } catch {}
        
        // If mediaSelections is `nil` the SDK will default to the AVURLAsset's `preferredMediaSelection`
        var mediaSelections = [AVMediaSelection]()
        
        if let avURLAsset = avURLAsset {
            mediaSelections = avURLAsset.allMediaSelections
            
            if let legibleMediaSelectionGroup = avURLAsset.mediaSelectionGroup(forMediaCharacteristic: .legible), let audibleMediaSelectionGroup = avURLAsset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
                
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
        
        BCOVOfflineVideoManager.shared()?.requestVideoDownload(video, mediaSelections: mediaSelections, parameters: videoDownload.paramaters, completion: { [weak self] (offlineVideoToken: String?, error: Error?) in
            
            DispatchQueue.main.async {

                if let error = error, let self = self {
                    
                    self.downloadInProgress = false
                    
                    // try again with another video
                    if #available(iOS 11.4, *)
                    {}
                    else
                    {
                        self.downloadVideoFromQueue()
                    }
                    
                    // Report any errors
                    if let offlineVideoToken = offlineVideoToken, let offlineVideo = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineVideoToken), let name = localizedNameForLocale(offlineVideo, nil) {
                        UIAlertController.show(withTitle: "Video Download Error (\(name))", andMessage: error.localizedDescription)
                    } else {
                        UIAlertController.show(withTitle: "Video Download Error", andMessage: error.localizedDescription)
                    }
                    
                    
                } else  {
                    
                    NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus, object: nil)
                    
                }
                
            }
            
        })
        
    }

}

// MARK: - Class Methods

extension DownloadManager {
    
    class func generateDownloadParameters() -> [String:Any] {
        
        // Get base license parameters
        var downloadParameters = DownloadManager.generateLicenseParameters()
        
        // Add bitrate parameter for the primary download
        let bitrate = AppDelegate.current().tabBarController.settingsViewController()?.bitrate() ?? 0
        
        print("Requested bitrate: \(bitrate)")
        
        downloadParameters[kBCOVOfflineVideoManagerRequestedBitrateKey] = bitrate
        
        return downloadParameters
    }
    
    class func generateLicenseParameters() -> [String:Any] {
        
        var licenseParamaters: [String:Any] = [:]
        
        // Generate the license parameters based on the Settings tab
        let isPurchaseLicense = AppDelegate.current().tabBarController.settingsViewController()?.isPurchaseLicenseType() ?? false
        // License details are only needed for FairPlay-protected videos.
        // It's harmless to add it for non-FairPlay videos too.
        
        if isPurchaseLicense {
            print("Requesting Purchase License")
            licenseParamaters[kBCOVFairPlayLicensePurchaseKey] = true
        } else {
            let rentalDuration = AppDelegate.current().tabBarController.settingsViewController()?.rentalDuration() ?? 0
            let playDuration = AppDelegate.current().tabBarController.settingsViewController()?.playDuration() ?? 0
            
            print("Requesting Rental License:\nrentalDuration: \(rentalDuration)")
            
            licenseParamaters[kBCOVFairPlayLicenseRentalDurationKey] = rentalDuration
            licenseParamaters[kBCOVFairPlayLicensePlayDurationKey] = playDuration
        }
        
        return licenseParamaters
    }
    
    class func mediaSelectionDescription(fromMediaSelection selection: AVMediaSelection, forToken token: String) -> String {
        // Get the offline video object and its path
        guard let offlineVideo = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: token), let videoPath = offlineVideo.properties[kBCOVOfflineVideoFilePathPropertyKey] as? String else {
            return "MediaSelection(n/a)"
        }
        
        let videoPathURL = URL(fileURLWithPath: videoPath)
        let urlAsset = AVURLAsset(url: videoPathURL)
        let desc = mediaSelectionDescription(fromMediaSelection: selection, withURLAsset: urlAsset)
        
        return desc
    }
    
    class func mediaSelectionDescription(fromMediaSelection selection: AVMediaSelection, withURLAsset asset: AVURLAsset) -> String {
        
        // Return a string description of the specified Media Selection.
        guard let legibleMSG = asset.mediaSelectionGroup(forMediaCharacteristic: .legible), let audibleMSG = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else {
            return "MediaSelection(n/a)"
        }
        let legibleDisplayName = selection.selectedMediaOption(in: legibleMSG)?.displayName ?? "-"
        let audibleDisplayName = selection.selectedMediaOption(in: audibleMSG)?.displayName ?? "-"
        return "MediaSelection(obj:\(selection), legible:\(legibleDisplayName), audible:\(audibleDisplayName))"
    }
    
    class func retrieveVideo(withVideoID videoID: String, completion: @escaping (BCOVVideo?, [AnyHashable:Any]?, Error?) -> Void) {
    
        // Retrieve a playlist through the BCOVPlaybackService
        let factory = BCOVPlaybackServiceRequestFactory(accountId: ConfigConstants.AccountID, policyKey: ConfigConstants.PolicyKey)
    
        guard let service = BCOVPlaybackService(requestFactory: factory) else {
            completion(nil, nil, nil)
            return
        }
        
        service.findVideo(withVideoID: videoID, parameters: nil, completion: { (video: BCOVVideo?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            completion(video, jsonResponse, error)
            
        })
        
    }
}

// MARK: - BCOVOfflineVideoManagerDelegate

extension DownloadManager: BCOVOfflineVideoManagerDelegate {
    
    func didCreateSharedBackgroundSesssionConfiguration(_ backgroundSessionConfiguration: URLSessionConfiguration!) {
        // Helps prevent downloads from appearing to sometimes stall
        backgroundSessionConfiguration.isDiscretionary = false
    }
    
    func offlineVideoToken(_ offlineVideoToken: String?, downloadTask: AVAssetDownloadTask?, didProgressTo progressPercent: TimeInterval) {
        // This delegate method reports progress for the primary video download
        let percentString = String(format: "%0.2f", progressPercent)
        print("Offline download didProgressTo: \(percentString) for token: \(offlineVideoToken!)")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus, object: nil)
            let downloadsVC = AppDelegate.current().tabBarController.downloadsViewController()
            downloadsVC?.updateInfoForSelectedDownload()
            downloadsVC?.refresh()
        }
    }
    
    func offlineVideoToken(_ offlineVideoToken: String!, aggregateDownloadTask: AVAggregateAssetDownloadTask!, didProgressTo progressPercent: TimeInterval, for mediaSelection: AVMediaSelection!) {
        // The specific requested media selected option related to this
        // offline video token has progressed to the specified percent
        if let offlineVideoToken = offlineVideoToken {
            print("aggregateDownloadTask:didProgressTo:\(progressPercent) for token: \(offlineVideoToken)")
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus, object: nil)
            let downloadsVC = AppDelegate.current().tabBarController.downloadsViewController()
            downloadsVC?.updateInfoForSelectedDownload()
            downloadsVC?.refresh()
        }
    }
    
    func offlineVideoToken(_ offlineVideoToken: String?, didFinishDownloadWithError error: Error?) {
        // The video has completed downloading
        
        if let error = error {
            print("Download finished with error: \(error.localizedDescription)")
        }
        
        downloadInProgress = false
        
        // Get the next video
        if #available(iOS 11.4, *)
        {}
        else
        {
            downloadVideoFromQueue()
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus, object: nil)
            let downloadsVC = AppDelegate.current().tabBarController.downloadsViewController()
            // We want to ensure 'updateInfoForSelectedDownload'
            // is called after we reload the table view with 'refresh'
            // instead of calling the methods async.
            // This is because we calculate downloadSize in
            // `cellForRowAtIndexPath:` and we want to make sure
            // we can reflect that data in the info label
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                downloadsVC?.updateInfoForSelectedDownload()
            })
            downloadsVC?.refresh()
            CATransaction.commit()
        }
    }
    
    func offlineVideoStorageDidChange() {

        // the offline storage changed. refresh to reflect new contents.
        let videosVC = AppDelegate.current().tabBarController.streamingViewController()
        videosVC?.updateStatus()
        
        let downloadsVC = AppDelegate.current().tabBarController.downloadsViewController()
        downloadsVC?.refresh()
        downloadsVC?.updateInfoForSelectedDownload()
    }
    
}
