//
//  DownloadsTableDataSource.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

fileprivate let videoCellReuseId = "VideoCell"

class DownloadsTableDataSource: NSObject {
    
    weak var tableView: UITableView?
    
    var downloadSizeDictionary: [String:Double] = [:]
    var offlineTokenArray: [String]?
    
    init(tableView: UITableView) {
        super.init()
        self.tableView = tableView
        tableView.register(UINib(nibName: "VideoTableViewCell", bundle: nil), forCellReuseIdentifier: videoCellReuseId)
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatus), name: OfflinePlayerNotifications.UpdateStatus, object: nil)
        updateStatus()
    }
    
    @objc private func updateStatus() {
        offlineTokenArray = BCOVOfflineVideoManager.shared()?.offlineVideoTokens
        tableView?.reloadData()
    }
    
    private func cacheDownloadedSize(forVideo video: BCOVVideo, withOfflineToken token: String) -> Double {
        
        guard let videoFilePath = video.properties[kBCOVOfflineVideoFilePathPropertyKey] as? String else {
            return 0
        }
        let videoSize = Utilities.directorySize(folderPath: videoFilePath)
        let megabytes = videoSize / (1000 * 1000)
        
        downloadSizeDictionary[token] = megabytes
        
        return megabytes
    }
    
    func removeOfflineToken(_ token: String) -> Bool {
        guard var updatedOfflineVideoTokenArray = offlineTokenArray, let indexOfToken = updatedOfflineVideoTokenArray.firstIndex(of: token) else {
            return false
        }
        updatedOfflineVideoTokenArray.remove(at: indexOfToken)
        offlineTokenArray = updatedOfflineVideoTokenArray
        return true
    }

}

// MARK: - UITableViewDataSource

extension DownloadsTableDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offlineTokenArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: videoCellReuseId, for: indexPath) as! VideoTableViewCell
        
        if let offlineToken = offlineTokenArray?[indexPath.row], let video = BCOVOfflineVideoManager.shared()?.videoObject(fromOfflineVideoToken: offlineToken), let offlineStatus = BCOVOfflineVideoManager.shared()?.offlineVideoStatus(forToken: offlineToken) {
            let downloadSize = downloadSizeDictionary[offlineToken] ?? cacheDownloadedSize(forVideo: video, withOfflineToken: offlineToken)
            cell.setup(withOfflineVideo: video, offlineStatus: offlineStatus, downloadSize: downloadSize)
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let count = offlineTokenArray?.count ?? 0
        let noun = (count > 1 || count == 0) ? "Videos" : "Video"
        return "\(count) Offline \(noun)"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        guard let statusArray = BCOVOfflineVideoManager.shared()?.offlineVideoStatus() else {
            return nil
        }
        
        let inProgressCount = statusArray.filter({ $0.downloadState == .stateDownloading }).count
        
        switch inProgressCount {
        case 0:
            return "No Videos Downloading"
        case 1:
            return "1 Video Is Still Downloading"
        default:
            return "\(inProgressCount) Videos Are Still Downloading"
        }

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let token = offlineTokenArray?[indexPath.row], removeOfflineToken(token) == true else {
            return
        }
        
        tableView.deleteRows(at: [indexPath], with: .right)
        
        AppDelegate.current().tabBarController.downloadsViewController()?.offlineVideoWasDeletedLocally(withToken: token)
        
    }
    
}
