//
//  VideoManager.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

enum VideoState {
    case OnlineOnly
    case Downloadable
    case Downloading
    case Paused
    case Cancelled
    case Downloaded
    case Error
}

class VideoManager: NSObject {
    
    weak var delegate: ReloadDelegate?
    
    var currentVideos: [BCOVVideo]?
    var currentPlaylistTitle: String?
    var currentPlaylistDescription: String?
    
    var imageCacheDictionary: [String:UIImage]?
    var videosTableViewData: [[String:Any]]?
    var estimatedDownloadSizeDictionary: [String:Double]?
    
    // Update the video dictionary array with the current status
    // as reported by the offline video manager
    func updateStatusForPlaylist() {
        
        guard let _videosTableViewData = videosTableViewData, let statusArray = BCOVOfflineVideoManager.shared()?.offlineVideoStatus() else {
            return
        }
        
        // Iterate through all the videos in our videos table,
        // and update the status for each one.
        
        var updatedData: [[String:Any]] = []
        
        for var videoDictionary in _videosTableViewData {
            
            guard let video = videoDictionary["video"] as? BCOVVideo else {
                continue
            }
            
            var found = false
            
            for offlineVideoStatus in statusArray {
                
                guard let offlineVideo = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineVideoStatus.offlineVideoToken) else {
                    continue
                }
                
                // Find the matching local video
                if video.matches(offlineVideo: offlineVideo) {
                    
                    // Match! Update status for this dictionary.
                    found = true
                    
                    switch offlineVideoStatus.downloadState {
                        case .licensePreloaded,
                             .stateRequested,
                             .stateTracksRequested,
                             .stateDownloading,
                             .stateTracksDownloading:
                        videoDictionary["state"] = VideoState.Downloading
                        case .stateSuspended,
                             .stateTracksSuspended:
                        videoDictionary["state"] = VideoState.Paused
                        case .stateCancelled,
                             .stateTracksCancelled:
                        videoDictionary["state"] = VideoState.Cancelled
                        case .stateCompleted,
                             .stateTracksCompleted:
                        videoDictionary["state"] = VideoState.Downloaded
                        case .stateError,
                             .stateTracksError:
                        videoDictionary["state"] = VideoState.Downloadable
                    }
                    
                }
                
            }
            
            if !found {
                videoDictionary["state"] = VideoState.Downloadable
            }
        
            updatedData.append(videoDictionary)
            
        }
        
        videosTableViewData = updatedData
        
    }
    
    func usePlaylist(_ playlist: [BCOVVideo], withBitrate bitrate: Int64) {
        
        // Re-initialize all the containers that store information
        // related to the videos in the current playlist
        imageCacheDictionary = [:]
        videosTableViewData = []
        estimatedDownloadSizeDictionary = [:]
        
        for video in playlist { 
            cacheThumbnail(forVideo: video)
            estimateDownloadSize(forVideo: video, withBitrate: bitrate)
        }
        
        updateStatusForPlaylist()
        
        delegate?.reloadData()
    }
    
    private func estimateDownloadSize(forVideo video: BCOVVideo, withBitrate bitrate: Int64) {
        
        // Estimate download size for each video
        BCOVOfflineVideoManager.shared()?.estimateDownloadSize(video, options: [kBCOVOfflineVideoManagerRequestedBitrateKey:bitrate], completion: { [weak self] (megabytes: Double, error: Error?) in
            
            guard let videoID = video.properties["id"] as? String else {
                return
            }
            
            // Store the estimated size in our dictionary
            // so we don't need to keep recomputing it
            // Use the video's id as the key
            self?.estimatedDownloadSizeDictionary?[videoID] = megabytes
            
            DispatchQueue.main.async {
                self?.delegate?.reloadRow(forVideo: video)
            }
            
        })
        
        let videoDictionary: [String:Any] = ["video": video, "state": video.canBeDownloaded ? VideoState.Downloadable : VideoState.OnlineOnly]
        
        videosTableViewData?.append(videoDictionary)
        
    }
    
    private func cacheThumbnail(forVideo video: BCOVVideo) {
        
        // Async task to get and store thumbnails
        DispatchQueue.global(qos: .default).async {
            
            // videoID is the key in the image cache dictionary
            guard let videoID = video.properties["id"] as? String, let thumbnailSources = video.properties["thumbnail_sources"] as? [[String:Any]] else {
                return
            }
            
            for thumbnailDictionary in thumbnailSources {
                
                guard let thumbnailURLString = thumbnailDictionary["src"] as? String, let thumbnailURL = URL(string: thumbnailURLString) else {
                    return
                }
                
                if thumbnailURL.scheme?.caseInsensitiveCompare("https") == .orderedSame {
                    
                    var thumbnailImageData: Data?
                    
                    do {
                        thumbnailImageData = try Data(contentsOf: thumbnailURL)
                    } catch let error {
                        print("Error getting thumbnail image data: \(error.localizedDescription)")
                    }
                    
                    guard let _thumbnailImageData = thumbnailImageData, let thumbnailImage = UIImage(data: _thumbnailImageData) else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        self.imageCacheDictionary?[videoID] = thumbnailImage
                        self.delegate?.reloadRow(forVideo: video)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}


