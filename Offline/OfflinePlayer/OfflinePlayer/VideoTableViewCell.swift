//
//  VideoTableViewCell.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


protocol VideoTableViewCellDelegate: class {
    func performDownload(forVideo video: BCOVVideo)
}


final class VideoTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var thumbnailImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var detailLabel: UILabel!
    @IBOutlet fileprivate weak var progressView: UIProgressView!

    fileprivate weak var video: BCOVVideo? {
        didSet {
            guard let video else { return }

            titleLabel.text = video.localizedName ?? "unknown"
            // Use red label to indicate that the video is protected with FairPlay
            titleLabel.textColor = video.usesFairPlay ? UIColor(red: 0.75,
                                                                green: 0.0,
                                                                blue: 0.0,
                                                                alpha: 1.0) : UIColor.black

            thumbnailImageView.backgroundColor = (thumbnail == nil ? .black : nil)
            thumbnailImageView.image = thumbnail ?? UIImage(named: "AppIcon")

            detailLabel.text = "\(video.duration) / \(fileSize)\n\(video.localizedShortDescription ?? "")"

            if video.offline,
               let offlineVideoToken = video.offlineVideoToken,
               let offlineManager = BCOVOfflineVideoManager.shared(),
               let offlineVideoStatus = offlineManager.offlineVideoStatus(forToken: offlineVideoToken) {
                progressView.isHidden = offlineVideoStatus.downloadState == .stateCompleted
                progressView.progress =  Float(offlineVideoStatus.downloadPercent / 100.0)
            }

            accessoryView = !(UIDevice.current.isSimulator && video.usesFairPlay) ? actionAccessoryView : nil
        }
    }

    fileprivate weak var delegate: VideoTableViewCellDelegate?

    fileprivate var thumbnail: UIImage? {
        guard let video else { return nil }

        if !video.offline {
            if let videoId = video.videoId {
                return VideoManager.shared.thumbnails[videoId]
            }
        } else {
            if let urlPath = video.properties[kBCOVOfflineVideoPosterFilePathPropertyKey] as? String,
               let image = UIImage(contentsOfFile: urlPath) {
                return image
            }
        }

        return nil
    }

    fileprivate var fileSize: String {
        guard let video else { return "" }

        if !video.offline {
            if let videoId = video.videoId,
               let downloadSize = VideoManager.shared.downloadSize[videoId] {
                return "\(String(format: "%0.2f", downloadSize)) MB"
            }
        } else {
            return UIDevice.current.usedDiskSpaceWithUnits(forVideo: video)
        }

        return "0.00 MB"
    }

    fileprivate var actionAccessoryView: UIImageView? {
        guard let video else { return nil }

        var imageView = video.canBeDownloaded ? UIImageView(image: UIImage(named: "arrow.down.circle")) : nil

        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatusArray = offlineManager.offlineVideoStatus() else {
            return imageView
        }

        for offlineVideoStatus in offlineVideoStatusArray {
            guard let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: offlineVideoStatus.offlineVideoToken),
                  offlineVideo.matches(with: video) else {
                continue
            }

            switch (offlineVideoStatus.downloadState) {
                case .stateRequested,
                        .stateDownloading,
                        .licensePreloaded:
                    imageView = UIImageView(image: UIImage(named: "arrow.triangle.circlepath"))
                    break

                case .stateSuspended:
                    imageView = UIImageView(image: UIImage(named: "pause.circle"))
                    break

                case .stateCancelled:
                    imageView = UIImageView(image: UIImage(named: "multiply.circle"))
                    imageView?.tintColor = .systemRed
                    break

                case .stateCompleted:
                    imageView = UIImageView(image: UIImage(named: "checkmark.circle"))
                    break

                case .stateError:
                    imageView = UIImageView(image: UIImage(named: "exclamationmark.circle"))
                    imageView?.tintColor = .systemRed
                    break
            }
        }

        guard !video.offline,
              let imageView else {
            return imageView
        }

        let tapGestureRecognize = UITapGestureRecognizer(target: self,
                                                         action: #selector(imageTapped(_:)))

        imageView.addGestureRecognizer(tapGestureRecognize)
        imageView.isUserInteractionEnabled = true

        return imageView
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        detailLabel.numberOfLines = 2
        detailLabel.lineBreakMode = .byTruncatingTail

        progressView.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        video = nil
        delegate = nil
        titleLabel.text = ""
        detailLabel.text = ""
    }

    func setup(with video: BCOVVideo?,
               and delegate: VideoTableViewCellDelegate? = nil) {
        self.delegate = delegate
        self.video = video
    }

    @objc
    fileprivate func imageTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended,
           let delegate,
           let video {
            delegate.performDownload(forVideo: video)
        }
    }
}
