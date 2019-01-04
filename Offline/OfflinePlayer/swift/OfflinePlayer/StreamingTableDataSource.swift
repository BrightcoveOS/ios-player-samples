//
//  StreamingTableDataSource.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

fileprivate let videoCellReuseId = "VideoCell"

class StreamingTableDataSource: NSObject {
    
    weak var tableView: UITableView?
    weak var videoManager: VideoManager?
    weak var downloadManager: DownloadManager?
    
    init(tableView: UITableView, videoManager: VideoManager, downloadManager: DownloadManager) {
        super.init()
        self.tableView = tableView
        self.videoManager = videoManager
        self.downloadManager = downloadManager
        tableView.register(UINib(nibName: "VideoTableViewCell", bundle: nil), forCellReuseIdentifier: videoCellReuseId)
    }

}

extension StreamingTableDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoManager?.videosTableViewData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: videoCellReuseId, for: indexPath) as! VideoTableViewCell
        
        if let videoDictionary = videoManager?.videosTableViewData?[indexPath.row],
            let video = videoDictionary["video"] as? BCOVVideo,
            let videoId = video.properties["id"] as? String,
            let estimatedDownloadSize = videoManager?.estimatedDownloadSizeDictionary?[videoId],
            let state = videoDictionary["state"] as? VideoState {
            let thumbnailImage = videoManager?.imageCacheDictionary?[videoId]
            cell.setup(withStreamingVideo: video, estimatedDownloadSize: estimatedDownloadSize, thumbnailImage: thumbnailImage, videoState: state)
            cell.delegate = self
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return videoManager?.currentPlaylistTitle
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return videoManager?.currentPlaylistDescription
    }
    
}

extension StreamingTableDataSource: VideoTableViewCellDelegate {
    
    func performDownload(forVideo video: BCOVVideo) {
        downloadManager?.doDownload(forVideo: video)
    }
    
}
