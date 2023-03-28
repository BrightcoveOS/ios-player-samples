//
//  ViewController.swift
//  BrightcoveCastReceiver
//
//  Created by Jeremy Blaker on 7/6/20.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleCast
import BrightcovePlayerSDK
import BrightcoveGoogleCast

fileprivate struct PlaybackConfig {
    static let PlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let AccountID = "5434391461001"
    static let PlaylistRefID = "brightcove-native-sdk-plist"
}

@objc class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var videoContainer: UIView!
        
        private var posters: [String:UIImage] = [:]
        private var playlist: BCOVPlaylist?
        private lazy var googleCastManager: BCOVGoogleCastManager = {
            let receiverAppConfig = BCOVReceiverAppConfig()
            receiverAppConfig.accountId = PlaybackConfig.AccountID
            receiverAppConfig.policyKey = PlaybackConfig.PlaybackServicePolicyKey
            receiverAppConfig.splashScreen = "https://solutions.brightcove.com/jblaker/cast-splash.jpg"
            
            // You can specify a customized player
            // receiverAppConfig.playerUrl = "https://players.brightcove.net/5434391461001/nVM2434Z1_default/index.min.js"
            
            // You can use the authToken property for PAS/EPA
            //receiverAppConfig.authToken = ""
            
            // You can use the adConfigId property for SSAI
            // Intended to be used alongside the SSAI Plugin for Brightcove Player SDK for iOS
            //receiverAppConfig.adConfigId = ""
            
            return BCOVGoogleCastManager(forBrightcoveReceiverApp: receiverAppConfig)
        }()

        lazy var playerView: BCOVPUIPlayerView? = {
            
            let options = BCOVPUIPlayerViewOptions()
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                options.presentingViewController = appDelegate.castContainerViewController
            }
            
            // Create PlayerUI views with normal VOD controls.
            let controlView = BCOVPUIBasicControlView.withVODLayout()
            guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: controlView) else {
                return nil
            }
            
            // Add to parent view
            self.videoContainer.addSubview(_playerView)
            _playerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                _playerView.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
                _playerView.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
                _playerView.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
                _playerView.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
                ])
            
            return _playerView
        }()
        
        lazy var playbackController: BCOVPlaybackController? = {
        
            guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController() else {
                return nil
            }
            
            _playbackController.isAutoAdvance = true
            _playbackController.isAutoPlay = true
            _playbackController.delegate = self
            
            googleCastManager.delegate = self
            
            _playbackController.add(googleCastManager)
            
            return _playbackController
            
        }()
        
        // MARK: - View Lifecycle
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            videoContainer.isHidden = true
            
            let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.castStateDidChange),
                                                   name: NSNotification.Name.gckCastStateDidChange,
                                                   object: GCKCastContext.sharedInstance())
            
            requestPlaylist()
            
            playerView?.playbackController = playbackController
            
            googleCastManager.delegate = self
        }

        // MARK: - Misc
        
        private func requestPlaylist() {
            let playbackService = BCOVPlaybackService(accountId: PlaybackConfig.AccountID, policyKey: PlaybackConfig.PlaybackServicePolicyKey)
            let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetReferenceID:PlaybackConfig.PlaylistRefID]
            playbackService?.findPlaylist(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (playlist: BCOVPlaylist?, json: [AnyHashable:Any]?, error: Error?) in

                guard let playlist = playlist else {
                    print("PlayerViewController Debug - Error retrieving video playlist")
                    return
                }

                self?.playlist = playlist
                self?.tableView.reloadData()

            })
        }
        
        // MARK: - Notification Handlers
        
        @objc private func castStateDidChange(_ notification: Notification) {
            let state = GCKCastContext.sharedInstance().castState
            
            switch state {
            case .noDevicesAvailable:
                print("No cast devices available")
            case .connected:
                print("Cast device connected")
            case .connecting:
                print("Cast device connecting")
            case .notConnected:
                print("Cast device not connected")
            }
        }

}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        videoContainer.isHidden = GCKCastContext.sharedInstance().castState == .connected
        
        if let videos = playlist?.videos, indexPath.section == 0 {
            playbackController?.setVideos(videos as NSFastEnumeration)
            return
        }
        
        if let video = self.playlist?.videos[indexPath.row] as? BCOVVideo {
        
            playbackController?.setVideos([video] as NSFastEnumeration)

        }
        
    }
    
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let _ = playlist {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let videos = playlist?.videos {
            return section == 0 ? 1 : videos.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Play All"
            return cell
        }
        
        guard let playlist = playlist, let video = playlist.videos[indexPath.row] as? BCOVVideo, let name = video.properties[kBCOVVideoPropertyKeyName] as? String else {
            return cell
        }

        cell.textLabel?.text = name

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return playlist?.properties[kBCOVVideoPropertyKeyName] as? String ?? nil
        }
        return nil
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd {
            videoContainer.isHidden = true
        }
    }
    
}

// MARK: - BCOVGoogleCastManagerDelegate

extension ViewController: BCOVGoogleCastManagerDelegate {

    func switched(toLocalPlayback lastKnownStreamPosition: TimeInterval, withError error: Error?) {
        if lastKnownStreamPosition > 0 {
            playbackController?.play()
        }
        videoContainer.isHidden = false

        if let _error = error {
            print("Switched to local playback with error: \(_error.localizedDescription)")
        }
    }

    func switchedToRemotePlayback() {
        videoContainer.isHidden = true
    }

    func currentCastedVideoDidComplete() {
        videoContainer.isHidden = true
    }

    func castedVideoFailedToPlay() {
        print("Failed to play casted video")
    }

    func suitableSourceNotFound() {
        print("Suitable source for video not found!")
    }

}
