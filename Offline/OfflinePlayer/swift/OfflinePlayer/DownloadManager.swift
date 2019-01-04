//
//  DownloadManager.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
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
    
    func doDownload(forVideo video: BCOVVideo) {
        
        if videoAlreadyProcessing(video) {
            return
        }
        
        // On iOS 11+, we get the license params,
        // and send the video off for preloading.
        // Additional tracks (subtitles, additional audio tracks)
        // are requested *after* the video is downloaded.
        if #available(iOS 11.0, *) {
            let downloadParamaters = DownloadManager.generateDownloadParameters()
            
            let videoDownload = VideoDownload(video: video, paramaters: downloadParamaters)
            
            // On iOS 10.3 and later we can perform video preloading
            videoPreloadQueue.append(videoDownload)
            
            runPreloadVideoQueue()
            
            return
        }
        
        // On iOS 10, we use Sideband Subtitles.
        // Subtitle tracks to be downloaded are specified up front.
        // To do this we find the alternative rendition attributes,
        // and create a list of languages out of them to pass as as an array.
        
        BCOVOfflineVideoManager.shared()?.alternativeRenditionAttributesDictionaries(for: video, completion: { [weak self] (alternativeRenditionAttributesDictionariesArray: [[AnyHashable:Any]]?, error: Error?) in
            
            DispatchQueue.main.async {
            
                if let error = error {
                    // Report any errors
                    UIAlertController.show(withTitle: "Video Download Error", andMessage: error.localizedDescription)
                    return
                }
                
                guard let strongSelf = self else {
                    return
                }
                
                var downloadParamaters = DownloadManager.generateDownloadParameters()
                
                // Collect array of languages here.
                // We're going to download all languages available in the video.
                let languagesArray = strongSelf.languagesArrayForAlternativeRenditions(attributesDictArray: alternativeRenditionAttributesDictionariesArray)
                
                if languagesArray.count > 0 {
                    downloadParamaters[kBCOVOfflineVideoManagerSubtitleLanguagesKey] = languagesArray
                }
                
                // iOS 10.3 allows us to preload the FairPlay license for each video
                if #available(iOS 10.3, *) {
                 
                    let videoDownload  = VideoDownload(video: video, paramaters: downloadParamaters)
                    
                    // On iOS 10.3 and later we can perform video preloading.
                    // Preloading the license makes for more reliable downloading
                    // when the app goes to the background.
                    strongSelf.videoPreloadQueue.append(videoDownload)
                    
                    strongSelf.runPreloadVideoQueue()
                    
                } else {
                 
                    // On iOS 10.2 and earlier, just download immediately
                    BCOVOfflineVideoManager.shared()?.requestVideoDownload(video, parameters: downloadParamaters, completion: { (offlineVideoToken: String?, error: Error?) in
                        
                        if let error = error {
                            UIAlertController.show(withTitle: "Video Download Error", andMessage: error.localizedDescription)
                            return
                        }
                        
                        // Success! Update our table with the new download status
                        NotificationCenter.default.post(name: OfflinePlayerNotifications.UpdateStatus, object: nil)
                        
                    })
                    
                }
                
            }
            
        })
        
    }
    
    private func languagesArrayForAlternativeRenditions(attributesDictArray: [[AnyHashable:Any]]?) -> [String] {
     
        // We want to download all subtitle/audio tracks
        // The methods for dowloading them are different on iOS 10 and iOS 11+.
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
                if let videoName = video.properties[kBCOVVideoPropertyKeyName] as? String {
                    UIAlertController.show(withTitle: "Video Already in Preload Queue", andMessage: "The video \(videoName) is already queued to be preloaded")
                }
                return true
            }
            
        }
        
        // First check to see if the video is in a download queue
        // videoDownloadQueue is an array of BCOVVideo objects
        for videoDict in videoDownloadQueue {
         
            if videoDict.video.matches(offlineVideo: video) {
                if let videoName = video.properties[kBCOVVideoPropertyKeyName] as? String {
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
                if let videoName = video.properties[kBCOVVideoPropertyKeyName] as? String {
                    UIAlertController.show(withTitle: "Video Already Downloaded", andMessage: "The video \(videoName) is already downloaded (or downloading)")
                    return true
                }
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
            if let videoName = video.properties["name"] as? String {
                print("Video \"\(videoName)\" does not use FairPlay; preloading not necessary")
            }
            
            videoDownloadQueue.append(videoDownload)
            
            delegate?.reloadRow(forVideo: video)
            runPreloadVideoQueue()
        } else {
            
            BCOVOfflineVideoManager.shared()?.preloadFairPlayLicense(video, parameters: videoDownload.paramaters, completion: { [weak self] (offlineVideoToken: String?, error: Error?) in
                
                DispatchQueue.main.async {
                    
                    if let error = error {
                        
                        let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineVideoToken)
                        let name = video?.properties["name"] as? String ?? "unknown"
                        
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
        if downloadInProgress {
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
            
            if let name = video.properties["name"] as? String {
                print("Variant Bitrates for video: \(name)")
            }
            
            if let bitrates = bitrates {
                for bitrate in bitrates {
                    print("\(bitrate.intValue)")
                }
            }
            
        })
        
        BCOVOfflineVideoManager.shared()?.requestVideoDownload(video, parameters: videoDownload.paramaters, completion: { [weak self] (offlineVideoToken: String?, error: Error?) in
            
            DispatchQueue.main.async {

                if let error = error {
                    
                    self?.downloadInProgress = false
                    
                    // try again with another video
                    self?.downloadVideoFromQueue()
                    
                    // Report any errors
                    if let offlineVideoToken = offlineVideoToken, let offlineVideo = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineVideoToken), let name = offlineVideo.properties["name"] {
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
            
            print("Requesting Rental License:\nrentalDuration: \(rentalDuration)")
            
            licenseParamaters[kBCOVFairPlayLicenseRentalDurationKey] = rentalDuration
        }
        
        return licenseParamaters
    }
    
    class func downloadAllSecondaryTracks(forOfflineVideoToken token: String) {
        
        // This demonstrates the "iOS 11 way" of downloading all secondary tracks
        // for your offline video.
        if #available(iOS 11.0, *) {
            
            // Get the offline video object
            guard let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: token), let offlineVideoPath = video.properties[kBCOVOfflineVideoFilePathPropertyKey] as? String else {
                return
            }
            
            // Get the path to the locally stored video and make an AVURLAsset out of it
            let videoPathURL = URL(fileURLWithPath: offlineVideoPath)
            
            let urlAsset = AVURLAsset(url: videoPathURL)
            
            // Get all the available media selections
            let mediaSelections = urlAsset.allMediaSelections
            
            if mediaSelections.count > 0 {
                // Log the list of media selections that will be downloaded:
                print("Found \(mediaSelections.count) media selections in \(token)")
                for mediaSelection in mediaSelections {
                    let desc = mediaSelectionDescription(fromMediaSelection: mediaSelection, forToken: token)
                    print("\(desc)")
                }
                
                BCOVOfflineVideoManager.shared()?.requestMediaSelectionsDownload(mediaSelections, offlineVideoToken: token)
                
            } else {
                print("There are no secondary tracks to download")
            }
            
        } else {
            print("Secondary tracks can only be downloaded with this method on iOS 11+.")
        }
        
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
    
    func offlineVideoToken(_ offlineVideoToken: String?, didFinishDownloadWithError error: Error?) {
        // The video has completed downloading
        
        // On iOS 10, any requested caption tracks will have been downloaded
        // along with the primary video.
        
        // On iOS 11+, after the video has downloaded, you can request that
        // additional tracks be downloaded.
        // In this app, a long press on the downloaded video will present
        // the option to download all extra tracks.
        
        if let error = error {
            print("Download finished with error: \(error.localizedDescription)")
        }
        
        downloadInProgress = false
        
        // Get the next video
        downloadVideoFromQueue()
        
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
