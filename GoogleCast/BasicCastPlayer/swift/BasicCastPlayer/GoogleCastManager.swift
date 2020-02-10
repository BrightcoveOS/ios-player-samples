//
//  GoogleCastManager.swift
//  BasicCastPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK
import GoogleCast

protocol GoogleCastManagerDelegate {
    
    var playbackController: BCOVPlaybackController? { get }
    
    func switchedToLocalPlayback(withLastKnownStreamPosition streamPosition: TimeInterval, withError error: Error?)
    func switchedToRemotePlayback()
    func castedVideoDidComplete()
    func castedVideoFailedToPlay()
    func suitableSourceNotFound()
    
}

class GoogleCastManager: NSObject {
    
    var delegate: GoogleCastManagerDelegate?
    
    private var sessionManager: GCKSessionManager
    private var castMediaController: GCKUIMediaController
    private var currentProgress: TimeInterval?
    private var currentVideo: BCOVVideo?
    private var castStreamPosition: TimeInterval?
    private let posterImageSize = CGSize(width: 480, height: 720)
    private var didContinueCurrentVideo: Bool = false
    private var suitableSourceNotFound: Bool = false
    private var castMediaInfo: GCKMediaInformation?
    
    override init() {
        sessionManager = GCKCastContext.sharedInstance().sessionManager
        castMediaController = GCKUIMediaController()
        super.init()
        sessionManager.add(self)
        castMediaController.delegate = self
    }
    
    private func findPreferredSource(fromSources sources: [BCOVSource], withHTTPS: Bool) -> BCOVSource? {
    
        // We prioritize HLS v3 > DASH > MP4
    
        let filteredSources = sources.filter { (source: BCOVSource) -> Bool in
            if withHTTPS {
                return source.url.absoluteString.hasPrefix("https://")
            }
            return source.url.absoluteString.hasPrefix("http://")
        }
        
        var hlsSource: BCOVSource?
        var dashSource: BCOVSource?
        var mp4Source: BCOVSource?
        
        for source in filteredSources {
            let urlString = source.url.absoluteString
            let deliveryMethod = source.deliveryMethod
            if urlString.contains("hls/v3") && deliveryMethod == "application/x-mpegURL" {
                hlsSource = source
                // This is our top priority so we can go ahead and break out of the loop
                break
            }
            if deliveryMethod == "application/dash+xml" {
                dashSource = source
            }
            if deliveryMethod == "video/mp4" {
                mp4Source = source
            }
        }
        
        if let hlsSource = hlsSource {
            return hlsSource
        }
        
        if let dashSource = dashSource {
            return dashSource
        }
        
        if let mp4Source = mp4Source {
            return mp4Source
        }
        
        return nil
        
    }
    
    private func createMediaInfo(fromVideo video: BCOVVideo) {
        
        var source: BCOVSource?
        
        // Don't restart the current video
        if let currentVideo = currentVideo {
            didContinueCurrentVideo = currentVideo.isEqual(to: video)
            if didContinueCurrentVideo {
                return
            }
        }
        
        suitableSourceNotFound = false
        
        // Try to find an HTTPS source first
        source = findPreferredSource(fromSources: video.sources, withHTTPS: true)
        
        if source == nil {
            source = findPreferredSource(fromSources: video.sources, withHTTPS: false)
        }
        
        // If no source was able to be found, let the delegate know
        // and do not continue
        guard let _source = source else {
            suitableSourceNotFound = true
            delegate?.suitableSourceNotFound()
            return
        }
        
        currentVideo = video
        
        let videoURL = _source.url.absoluteString
        let name = video.properties[kBCOVVideoPropertyKeyName] as! String
        let durationNumber = video.properties[kBCOVVideoPropertyKeyDuration] as! NSNumber
        
        let metaData = GCKMediaMetadata(metadataType: .generic)
        metaData.setString(name, forKey: kGCKMetadataKeyTitle)
        
        if let poster = video.properties[kBCOVVideoPropertyKeyPoster] as? String, let imageURL = URL(string: poster) {
            let image = GCKImage(url: imageURL, width:Int(posterImageSize.width), height:Int(posterImageSize.height))
            metaData.addImage(image)
        }
        
        var mediaTracks = [GCKMediaTrack]()
        
        let textTracks = video.properties[kBCOVVideoPropertyKeyTextTracks] as! [[String:AnyHashable]]
        
        var trackIdentifier = 0
        
        for track in textTracks {
            trackIdentifier += 1
            let src = track["src"] as! String
            let lang = track["srclang"] as! String
            let name = track["label"] as! String
            var contentType = track["mime_type"] as! String
            if contentType == "text/webvtt" {
                // The Google Cast SDK doesn't seem to understand text/webvtt
                // Simply setting the content type as text/vtt seems to work
                contentType = "text/vtt"
            }
            let kind = track["kind"] as! String
            var trackType: GCKMediaTextTrackSubtype = .unknown
            if kind == "captions" || kind == "subtitles" {
                trackType = kind == "captions" ? .captions : .subtitles
                let captionsTrack = GCKMediaTrack(identifier: trackIdentifier, contentIdentifier: src, contentType: contentType, type: .text, textSubtype: trackType, name: name, languageCode: lang, customData: nil)
                mediaTracks.append(captionsTrack)
            }
        }
        
        let builder = GCKMediaInformationBuilder()
        builder.contentID = videoURL
        builder.streamType = .unknown
        builder.contentType = source?.deliveryMethod
        builder.metadata = metaData
        builder.streamDuration = durationNumber.doubleValue
        builder.mediaTracks = mediaTracks
        
        castMediaInfo = builder.build()
    }
    
    private func setupRemoteMediaClientWithMediaInfo() {
        
        // Don't load media if the video is what is already playing
        // or if we couldn't find a suitable source for the video
        if didContinueCurrentVideo || suitableSourceNotFound {
            return
        }
        
        guard let currentProgress = currentProgress, let playbackController = delegate?.playbackController else {
            return
        }
        
        let options = GCKMediaLoadOptions()
        options.playPosition = currentProgress
        options.autoplay = playbackController.isAutoPlay
        
        if let castSession = GCKCastContext.sharedInstance().sessionManager.currentSession, let remoteMediaClient = castSession.remoteMediaClient, let castMediaInfo = castMediaInfo {
            remoteMediaClient.loadMedia(castMediaInfo, with: options)
        }
        
    }
    
    private func switchToRemotePlayback() {
        // Pause local player
        delegate?.playbackController?.pause()
        delegate?.switchedToRemotePlayback()
    }
    
    private func switchToLocalPlayback(withError error: Error?) {
        // Play local player
        let lastKnownStreamPosition = castMediaController.lastKnownStreamPosition
        
        guard let playbackController = delegate?.playbackController else {
            return
        }
        
        playbackController.seek(to: CMTime(seconds: lastKnownStreamPosition, preferredTimescale: 600)) { [weak self] (finished: Bool) in
            self?.delegate?.switchedToLocalPlayback(withLastKnownStreamPosition: lastKnownStreamPosition, withError: error)
        }
    }

}

// MARK: - GCKSessionManagerListener

extension GoogleCastManager: GCKSessionManagerListener {
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        switchToRemotePlayback()
        setupRemoteMediaClientWithMediaInfo()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        switchToRemotePlayback()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        switchToLocalPlayback(withError: error)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        switchToLocalPlayback(withError: error)
    }
        
}

// MARK: - BCOVPlaybackSessionConsumer

extension GoogleCastManager: BCOVPlaybackSessionConsumer {
    
    func didAdvance(to session: BCOVPlaybackSession!) {
        createMediaInfo(fromVideo: session.video)
        setupRemoteMediaClientWithMediaInfo()
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        currentProgress = progress
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if let _ = GCKCastContext.sharedInstance().sessionManager.currentSession {
            
            if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventReady {
                switchToRemotePlayback()
            }
            
        }
 
    }
    
}

// MARK: - GCKUIMediaControllerDelegate

extension GoogleCastManager: GCKUIMediaControllerDelegate {
    
    func mediaController(_ mediaController: GCKUIMediaController, didUpdate mediaStatus: GCKMediaStatus) {
        
        // Once the video has finished, let the delegate know
        // and attempt to proceed to the next session, if autoAdvance
        // is enabled
        if mediaStatus.idleReason == .finished {
            
            currentVideo = nil
            
            guard let delegate = delegate else {
                return
            }
            
            delegate.castedVideoDidComplete()
            
            if let playbackController = delegate.playbackController {
                if playbackController.isAutoAdvance {
                    playbackController.advanceToNext()
                }
            }
            
        }
        
        if mediaStatus.idleReason == .error {
            
            currentVideo = nil
            
            guard let delegate = delegate else {
                return
            }
            
            delegate.castedVideoFailedToPlay()
            
        }
        
        castStreamPosition = mediaStatus.streamPosition
        
    }
    
}
