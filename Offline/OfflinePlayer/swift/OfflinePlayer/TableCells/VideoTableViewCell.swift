//
//  VideoTableViewCell.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

class VideoTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.isHidden = true
        }
    }
    
    weak var video: BCOVVideo?
    weak var delegate: VideoTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cleanup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cleanup()
    }
    
    private func cleanup() {
        titleLabel.text = nil
        detailsLabel.text = nil
        thumbnailImageView.image = nil
        statusButton.setImage(nil, for: .normal)
    }
    
    private func updateStatusButtonImage(_ state: VideoState) {
        
        var stateImage: UIImage?
        
        switch state {
        case .OnlineOnly:
                break;
        case .Downloadable:
            stateImage = UIImage(named: "download")
        case .Downloading:
            stateImage = UIImage(named: "inprogress")
        case .Paused:
            stateImage = UIImage(named: "paused")
        case .Downloaded:
            stateImage = UIImage(named: "downloaded")
        case .Cancelled:
            stateImage = UIImage(named: "cancelled")
        case .Error:
            stateImage = UIImage(named: "error")
        }
        
        DispatchQueue.main.async {
            self.statusButton.setImage(stateImage, for: .normal)
        }
        
    }
    
    private func handleDownloadState(offlineStatus: BCOVOfflineVideoStatus) {
        
        switch offlineStatus.downloadState {
            case .licensePreloaded,
                 .stateRequested,
                 .stateTracksRequested,
                 .stateDownloading,
                 .stateTracksDownloading:
            updateStatusButtonImage(.Downloading)
            case .stateSuspended,
                 .stateTracksSuspended:
            updateStatusButtonImage(.Paused)
            case .stateCancelled,
                 .stateTracksCancelled:
            updateStatusButtonImage(.Cancelled)
            case .stateCompleted,
                 .stateTracksCompleted:
            updateStatusButtonImage(.Downloaded)
            case .stateError,
                 .stateTracksError:
            updateStatusButtonImage(.Error)
        }
        
    }
    
    func setup(withStreamingVideo video: BCOVVideo, estimatedDownloadSize: Double, thumbnailImage: UIImage?, videoState: VideoState) {
        
        self.video = video
        
        setupTitleLabel(withVideo: video)
        
        let detailString = getDetailString(forVideo: video)
        
        // Detail text is two lines consisting of:
        // "duration in seconds / estimated download size)"
        // "reference_id"
        if let durationNumber = video.properties["duration"] as? NSNumber {
            // raw duration is in milliseconds
            let duration = durationNumber.intValue / 1000
            let twoLineDetailString = "\(duration) sec / \(formattedSizeString(filesize: estimatedDownloadSize)) MB \n\(detailString)"
            
            detailsLabel.text = twoLineDetailString
        }
        
        // Use cached thumbnail image for dipslay
        thumbnailImageView.image = thumbnailImage ?? UIImage(named: "bcov")
        
        updateStatusButtonImage(videoState)
        
        statusButton.isUserInteractionEnabled = true
    }
    
    func setup(withOfflineVideo video: BCOVVideo, offlineStatus: BCOVOfflineVideoStatus, downloadSize: Double) {
        
        setupTitleLabel(withVideo: video)
        
        let detailString = getDetailString(forVideo: video)
        var twoLineDetailString: String?
        
        // Detail text is two lines consisting of:
        // "duration in seconds / actual download size)"
        // "reference_id"
        if let durationNumber = video.properties["duration"] as? NSNumber {
        
            let duration = durationNumber.intValue / 1000
            
            if offlineStatus.downloadState == .stateCompleted {
                
                // download complete: show the downloaded video size
                
                // Use Kilobytes if the measurement is too small
                if downloadSize < 0.5 {
                    let kilobytes = downloadSize * 1000
                    twoLineDetailString = "\(duration) sec / \(formattedSizeString(filesize: kilobytes)) KB\n\(detailString)"
                } else {
                    twoLineDetailString = "\(duration) sec / \(formattedSizeString(filesize: downloadSize)) MB\n\(detailString)"
                }
                
                
            } else {
                // download not complete: skip the download size
                twoLineDetailString = "\(duration) sec / -- MB\n\(detailString)"
            }
            
            detailsLabel.text = twoLineDetailString
            
        }
        
        // Set the thumbnail image
        if let thumbnailPathString = video.properties[kBCOVOfflineVideoThumbnailFilePathPropertyKey] as? String {
            let thumbnailImage = UIImage(contentsOfFile: thumbnailPathString)
            thumbnailImageView?.image = thumbnailImage ?? UIImage(named: "bcov")
        }
        
        handleDownloadState(offlineStatus: offlineStatus)
        
        progressView.isHidden = false
        updateProgressView(withPercentage: offlineStatus.downloadPercent)
        
        statusButton.setImage(UIImage(named: "downloaded"), for: .normal)
        statusButton.isUserInteractionEnabled = false
    }
    
    private func updateProgressView(withPercentage percentage: CGFloat) {
        self.progressView.setProgress(Float(percentage / 100.0), animated: true)
    }
    
    private func formattedSizeString(filesize: Double) -> String {
        return String(format: "%0.2f", filesize)
    }
    
    private func getDetailString(forVideo video: BCOVVideo) -> String {
        guard let detailString = video.properties["description"] as? String else {
            return video.properties["reference_id"] as? String ?? ""
        }
        
        return detailString
    }
    
    private func setupTitleLabel(withVideo video: BCOVVideo) {
        titleLabel.text = video.properties["name"] as? String
        
        // Use red label to indicate that the video is protected with FairPlay
        titleLabel.textColor = video.usesFairPlay ? UIColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 1.0) : UIColor.black
    }
    
    @IBAction private func downloadButtonPressed(_ button: UIButton) {
        if let video = video {
            delegate?.performDownload(forVideo: video)
        }
    }

}

protocol VideoTableViewCellDelegate: class {
    func performDownload(forVideo: BCOVVideo)
}
