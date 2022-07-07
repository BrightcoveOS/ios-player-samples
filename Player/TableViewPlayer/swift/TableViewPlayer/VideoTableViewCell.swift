//
//  VideoTableViewCell.swift
//  MultiplePlayersSample
//
//  Created by Jeremy Blaker on 6/9/22.
//

import UIKit
import BrightcovePlayerSDK
import AVKit

class VideoTableViewCell: UITableViewCell {
    
    static let UnmuteNotification = Notification.Name("VideoDidUnmute")
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var muteButton: UIButton! {
        didSet {
            muteButton.tintColor = .black
        }
    }
    
    private weak var playbackConfiguration: PlaybackConfiguration?
    private var playerView: BCOVPUIPlayerView?
    
    // MARK: - Lifecycle

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
        
        // Build the BCOVUIPlayerView for this cell
        buildPlayerView()
        
        // Handle when another video is unmuted
        NotificationCenter.default.addObserver(self, selector: #selector(unmuteNotificationReceived(_:)), name: VideoTableViewCell.UnmuteNotification, object: nil)
        
        // Handle when the table view stops scrolling
        // We want to play videos in when this happens
        NotificationCenter.default.addObserver(self, selector: #selector(scrollingStoppedNotificationReceived(_:)), name: ViewController.ScrollingStoppedNotification, object: nil)
        
        // Handle when the table view starts scrolling
        // We want to pause videos when this happens
        NotificationCenter.default.addObserver(self, selector: #selector(scrollingStartedNotificationReceived(_:)), name: ViewController.ScrollingStartedNotification, object: nil)
    }
    
    // MARK: - Notifications
    
    @objc
    private func unmuteNotificationReceived(_ notification: Notification) {
        guard let player = playbackConfiguration?.playbackSession?.player,
              let cell = notification.object as? VideoTableViewCell
        else {
            return
        }
    
        // Mute all videos except the one for this cell
        if cell != self {
            player.isMuted = true
            updateMuteButton()
        }
    }
    
    @objc
    private func scrollingStoppedNotificationReceived(_ notification: Notification) {
        playbackConfiguration?.playbackController?.play()
    }
    
    @objc
    private func scrollingStartedNotificationReceived(_ notification: Notification) {
        playbackConfiguration?.playbackController?.pause()
    }
    
    // MARK: - Public Methods
    
    public func setUpWith(video: BCOVVideo, playbackConfiguration: PlaybackConfiguration) {
        self.playbackConfiguration = playbackConfiguration
        playerView?.playbackController = playbackConfiguration.playbackController
        if let videoTitle = video.properties[kBCOVVideoPropertyKeyName] as? String {
            videoLabel.text = videoTitle
        }
    }
    
    // MARK: - Private Methods
    
    private func buildPlayerView() {
        let options = BCOVPUIPlayerViewOptions()

        guard let newPlayerView = BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return
        }
        
        videoContainer.addSubview(newPlayerView)
        newPlayerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newPlayerView.topAnchor.constraint(equalTo: videoContainer.topAnchor),
            newPlayerView.rightAnchor.constraint(equalTo: videoContainer.rightAnchor),
            newPlayerView.leftAnchor.constraint(equalTo: videoContainer.leftAnchor),
            newPlayerView.bottomAnchor.constraint(equalTo: videoContainer.bottomAnchor)
        ])
        
        playerView = newPlayerView
    }
    
    private func updateMuteButton() {
        guard let player = playbackConfiguration?.playbackSession?.player else {
            return
        }
        
        let title = player.isMuted ? "Unmute" : "Mute"
        muteButton.setTitle(title, for: .normal)
    }
    
    // MARK: - IBActions
    
    @IBAction func toggleVideoMute() {
        guard let player = playbackConfiguration?.playbackSession?.player else {
            return
        }

        player.isMuted = !player.isMuted

        updateMuteButton()

        if !player.isMuted {
            NotificationCenter.default.post(name: VideoTableViewCell.UnmuteNotification, object: self)
        }
    }

}

