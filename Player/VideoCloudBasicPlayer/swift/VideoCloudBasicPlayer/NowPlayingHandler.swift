//
//  NowPlayingHandler.swift
//  VideoCloudBasicPlayer
//
//  Created by Jeremy Blaker on 3/20/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

class NowPlayingHandler: NSObject {
    
    private weak var playbackController: BCOVPlaybackController?
    private var nowPlayingInfo: [String:AnyHashable]?
    private weak var session: BCOVPlaybackSession?
    private var observerContext = 0
    
    init(withPlaybackController playbackController: BCOVPlaybackController) {
        self.playbackController = playbackController
        super.init()
        playbackController.add(self)
        setup()
    }
    
    deinit {
        if let session = session as? NSObject {
            session.removeObserver(self, forKeyPath: "player.rate")
        }
    }

    private func setup() {
        let center = MPRemoteCommandCenter.shared()
        
        center.pauseCommand.addTarget(self, action: #selector(pauseCommand))
        center.playCommand.addTarget(self, action: #selector(playCommand))
        center.togglePlayPauseCommand.addTarget(self, action: #selector(playPauseCommand))
    }

    @objc func pauseCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        playbackController?.pause()
        return .success
    }
    
    @objc func playCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        playbackController?.play()
        return .success
    }
    
    @objc func playPauseCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if session?.player.rate == 0 {
            playbackController?.play()
        } else {
            playbackController?.pause()
        }
        
        return .success
    }
    
    func updateNowPlayingInfoForAudioOnly() {
        guard let customFields = self.session?.video.properties["custom_fields"] as? [String:Any] else {
            return
        }
        
        nowPlayingInfo?[MPMediaItemPropertyMediaType] = MPMediaType.music.rawValue
        
        // These custom_fields values can be configured in VideoCloud
        // https://beacon.support.brightcove.com/syncing-with-video-cloud/vc-custom-fields.html
        
        if let albumName = customFields["album_name"] as? String {
            nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = albumName
        }
        
        if let albumArtist = customFields["album_artist"] as? String {
            nowPlayingInfo?[MPMediaItemPropertyArtist] = albumArtist
        }
        
        let infoCenter = MPNowPlayingInfoCenter.default()
        infoCenter.nowPlayingInfo = nowPlayingInfo
    }
}

extension NowPlayingHandler {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if let _session = session as? NSObject, let _object = object as? NSObject, let rate = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
            if _object == _session && keyPath == "player.rate" {
                guard var _nowPlayingInfo = nowPlayingInfo else {
                    return
                }
                let infoCenter = MPNowPlayingInfoCenter.default()
                _nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
                infoCenter.nowPlayingInfo = _nowPlayingInfo
                self.nowPlayingInfo = _nowPlayingInfo
            }
        }

    }
}

extension NowPlayingHandler: BCOVPlaybackSessionConsumer {
    
    func didAdvance(to session: BCOVPlaybackSession!) {
        
        if let prevSession = self.session as? NSObject {
            prevSession.removeObserver(self, forKeyPath: "player.rate")
        }
        
        self.session = session
        
        if let newSession = session as? NSObject {
            newSession.addObserver(self, forKeyPath: "player.rate", options: NSKeyValueObservingOptions([.new, .initial]), context: &observerContext)
        }
        
        nowPlayingInfo = [String:AnyHashable]()
        guard let videoName = localizedNameForLocale(session.video, nil), let durationNum = session.video.properties[kBCOVVideoPropertyKeyDuration] as? NSNumber else {
            return
        }
        
        let duration = Double(durationNum.doubleValue / 1000)
        
        nowPlayingInfo?[MPMediaItemPropertyTitle] = videoName
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = NSNumber(floatLiteral: duration)
        
        let infoCenter = MPNowPlayingInfoCenter.default()
        infoCenter.nowPlayingInfo = nowPlayingInfo

        if let posterURLString = session.video.properties[kBCOVVideoPropertyKeyPoster] as? String, let posterURL = URL(string: posterURLString) {
            DispatchQueue.global(qos: .background).async {
                do {
                    let imageData = try Data(contentsOf: posterURL)
                    if let image = UIImage(data: imageData) {
                        self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
                            return image
                        }
                        let infoCenter = MPNowPlayingInfoCenter.default()
                        infoCenter.nowPlayingInfo = self.nowPlayingInfo
                    }
                } catch {}

            }
        }
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        if progress.isInfinite {
            return
        }
        let infoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(integerLiteral: Int(progress))
        infoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
