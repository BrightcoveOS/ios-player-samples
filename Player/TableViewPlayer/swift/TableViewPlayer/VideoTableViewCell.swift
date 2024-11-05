//
//  VideoTableViewCell.swift
//  TableViewPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Foundation
import UIKit
import BrightcovePlayerSDK


let UnmuteNotification = Notification.Name("VideoDidUnmute")


final class VideoTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var videoLabel: UILabel!
    @IBOutlet fileprivate weak var muteButton: UIButton! {
        didSet {
            muteButton.tintColor = .black
        }
    }
    
    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        
        let controlsView = BCOVPUIBasicControlView.withVODLayout()
        if let allLayoutItems = controlsView?.layout.allLayoutItems,
           let screenModeButton = allLayoutItems.first(where: { ($0 as? BCOVPUILayoutView)?.tag == BCOVPUIViewTag.buttonScreenMode.rawValue }) as? BCOVPUILayoutView {
            screenModeButton.isRemoved = true
        }
        
        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: controlsView) else {
            return nil
        }
        
        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)
        
        return playerView
    }()
    
    fileprivate weak var playbackConfiguration: PlaybackConfiguration?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        playbackConfiguration?.playbackController?.pause()
        if let player = playbackConfiguration?.playbackSession?.player {
            player.isMuted = true
            updateMuteButton()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Handle when another video is unmuted
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(unmuteNotificationReceived(_:)),
                                               name: UnmuteNotification,
                                               object: nil)
        
        // Handle when the table view stops scrolling
        // We want to play videos in when this happens
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollingStoppedNotificationReceived(_:)),
                                               name: ScrollingStoppedNotification,
                                               object: nil)
        
        // Handle when the table view starts scrolling
        // We want to pause videos when this happens
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollingStartedNotificationReceived(_:)),
                                               name: ScrollingStartedNotification,
                                               object: nil)
    }
    
    func setUpWith(video: BCOVVideo,
                   playbackConfiguration: PlaybackConfiguration) {
        self.playbackConfiguration = playbackConfiguration
        
        if let playerView,
           let playbackController = playbackConfiguration.playbackController {
            playerView.playbackController = playbackController
        }
        
        if let videoTitle = video.properties[BCOVVideo.PropertyKeyName] as? String {
            videoLabel.text = videoTitle
        }
    }
    
    @objc
    fileprivate func unmuteNotificationReceived(_ notification: Notification) {
        guard let player = playbackConfiguration?.playbackSession?.player,
              let cell = notification.object as? VideoTableViewCell else {
            return
        }
        
        // Mute all videos except the one for this cell
        if cell != self {
            player.isMuted = true
            updateMuteButton()
        }
    }
    
    fileprivate func updateMuteButton() {
        guard let player = playbackConfiguration?.playbackSession?.player else {
            return
        }
        
        let title = player.isMuted ? "Unmute" : "Mute"
        muteButton.setTitle(title, for: .normal)
    }
    
    @objc
    fileprivate func scrollingStoppedNotificationReceived(_ notification: Notification) {
        playbackConfiguration?.playbackController?.play()
    }
    
    @objc
    fileprivate func scrollingStartedNotificationReceived(_ notification: Notification) {
        playbackConfiguration?.playbackController?.pause()
    }
    
    @IBAction
    fileprivate func toggleVideoMute() {
        guard let player = playbackConfiguration?.playbackSession?.player else {
            return
        }
        
        player.isMuted = !player.isMuted
        
        updateMuteButton()
        
        if !player.isMuted {
            NotificationCenter.default.post(name: UnmuteNotification,
                                            object: self)
        }
    }
}
