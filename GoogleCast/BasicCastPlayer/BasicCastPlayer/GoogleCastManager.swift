//
//  GoogleCastManager.swift
//  BasicCastPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import GoogleCast
import BrightcovePlayerSDK


protocol GoogleCastManagerDelegate {

    var playbackController: BCOVPlaybackController? { get }

    func switchedToLocalPlayback(withLastKnownStreamPosition streamPosition: TimeInterval,
                                 withError error: Error?)
    func switchedToRemotePlayback()
    func castedVideoDidComplete()
    func castedVideoFailedToPlay()
    func suitableSourceNotFound()
}


final class GoogleCastManager: NSObject {

    var delegate: GoogleCastManagerDelegate?

    fileprivate var sessionManager: GCKSessionManager
    fileprivate var castMediaController: GCKUIMediaController
    fileprivate var currentProgress: TimeInterval?
    fileprivate var currentVideo: BCOVVideo?
    fileprivate var castStreamPosition: TimeInterval?
    fileprivate let posterImageSize = CGSize(width: 480,
                                             height: 720)
    fileprivate var didContinueCurrentVideo: Bool = false
    fileprivate var suitableSourceNotFound: Bool = false
    fileprivate var castMediaInfo: GCKMediaInformation?

    override init() {
        sessionManager = GCKCastContext.sharedInstance().sessionManager
        castMediaController = GCKUIMediaController()
        super.init()
        sessionManager.add(self)
        castMediaController.delegate = self
    }

    fileprivate func findPreferredSource(fromSources sources: [BCOVSource],
                                         withHTTPS: Bool) -> BCOVSource? {
        // We prioritize HLS v3 > DASH v1 > MP4
        let filteredSources = sources.filter { (source: BCOVSource) -> Bool in
            if let url = source.url {
                if withHTTPS {
                    return url.absoluteString.hasPrefix("https://")
                }

                return url.absoluteString.hasPrefix("http://")
            }else{
                return false
            }
        }

        var hlsSource: BCOVSource?
        var dashSource: BCOVSource?
        var mp4Source: BCOVSource?

        for source in filteredSources {
            let urlString = source.url!.absoluteString
            let deliveryMethod = source.deliveryMethod

            if urlString.contains("hls/v3") &&
                deliveryMethod == "application/x-mpegURL" {
                hlsSource = source
                // This is our top priority so we can go ahead and break out of the loop
                break
            }

            if urlString.contains("v1/dash") &&
                deliveryMethod == "application/dash+xml" {
                dashSource = source
            }

            if deliveryMethod == "video/mp4" {
                mp4Source = source
            }
        }

        if let hlsSource {
            return hlsSource
        }

        if let dashSource {
            return dashSource
        }

        if let mp4Source {
            return mp4Source
        }

        return nil

    }

    fileprivate func createMediaInfo(fromVideo video: BCOVVideo) {

        var source: BCOVSource?

        // Don't restart the current video
        if let currentVideo {
            didContinueCurrentVideo = currentVideo.isEqual(video)
            if didContinueCurrentVideo { return }
        }

        suitableSourceNotFound = false

        // Try to find an HTTPS source first
        source = findPreferredSource(fromSources: video.sources,
                                     withHTTPS: true)

        if source == nil {
            source = findPreferredSource(fromSources: video.sources,
                                         withHTTPS: false)
        }

        // If no source was able to be found, let the delegate know
        // and do not continue
        guard let source, let url = source.url else {
            suitableSourceNotFound = true
            delegate?.suitableSourceNotFound()
            return
        }

        currentVideo = video

        let videoURL = url.absoluteString
        let name = video.properties[BCOVVideo.PropertyKeyName] as! String
        let durationNumber = video.properties[BCOVVideo.PropertyKeyDuration] as! NSNumber

        let metaData = GCKMediaMetadata(metadataType: .generic)
        metaData.setString(name, forKey: kGCKMetadataKeyTitle)

        if let poster = video.properties[BCOVVideo.PropertyKeyPoster] as? String,
           let imageURL = URL(string: poster) {
            let image = GCKImage(url: imageURL,
                                 width:Int(posterImageSize.width),
                                 height:Int(posterImageSize.height))
            metaData.addImage(image)
        }

        var mediaTracks = [GCKMediaTrack]()

        let textTracks = video.properties[BCOVVideo.PropertyKeyTextTracks] as! [[String: AnyHashable]]

        var trackIdentifier = 0

        for track in textTracks {
            trackIdentifier += 1
            guard let src = track["src"] as? String,
                  let lang = track["srclang"] as? String,
                  let name = track["label"] as? String,
                  let kind = track["kind"] as? String,
                  var contentType = track["mime_type"] as? String else {
                continue
            }

            if contentType == "text/webvtt" {
                // The Google Cast SDK doesn't seem to understand text/webvtt
                // Simply setting the content type as text/vtt seems to work
                contentType = "text/vtt"
            }

            var trackType: GCKMediaTextTrackSubtype = .unknown
            if kind == "captions" || kind == "subtitles" {
                trackType = kind == "captions" ? .captions : .subtitles
                if let captionsTrack = GCKMediaTrack(identifier: trackIdentifier,
                                                     contentIdentifier: src,
                                                     contentType: contentType,
                                                     type: .text,
                                                     textSubtype: trackType,
                                                     name: name,
                                                     languageCode: lang,
                                                     customData: nil) {
                    mediaTracks.append(captionsTrack)
                }
            }
        }

        let builder = GCKMediaInformationBuilder()
        builder.contentID = videoURL
        builder.streamType = .unknown
        builder.contentType = source.deliveryMethod
        builder.metadata = metaData
        builder.streamDuration = durationNumber.doubleValue
        builder.mediaTracks = mediaTracks

        castMediaInfo = builder.build()
    }

    fileprivate func setupRemoteMediaClientWithMediaInfo() {
        // Don't load media if the video is what is already playing
        // or if we couldn't find a suitable source for the video
        if didContinueCurrentVideo || suitableSourceNotFound {
            return
        }

        guard let playbackController = delegate?.playbackController else {
            return
        }

        let options = GCKMediaLoadOptions()
        if let currentProgress {
            options.playPosition = currentProgress > 0 ? currentProgress : 0
        } else {
            options.playPosition = 0
        }

        options.autoplay = playbackController.isAutoPlay

        if let castSession = GCKCastContext.sharedInstance().sessionManager.currentSession,
           let remoteMediaClient = castSession.remoteMediaClient,
           let castMediaInfo = castMediaInfo {
            remoteMediaClient.loadMedia(castMediaInfo, with: options)
        }
    }

    fileprivate func switchToRemotePlayback() {
        guard let delegate else { return }

        // Pause local player
        delegate.playbackController?.pause()
        delegate.switchedToRemotePlayback()
    }

    fileprivate func switchToLocalPlayback(withError error: Error?) {
        guard let delegate,
              let playbackController = delegate.playbackController else {
            return
        }

        // Play local player
        let lastKnownStreamPosition = castMediaController.lastKnownStreamPosition

        playbackController.seek(to: CMTime(seconds: lastKnownStreamPosition,
                                           preferredTimescale: 600)) {
            [weak self] (finished: Bool) in
            self?.delegate?.switchedToLocalPlayback(withLastKnownStreamPosition: lastKnownStreamPosition,
                                                    withError: error)
        }
    }

}


// MARK: - BCOVPlaybackSessionConsumer

extension GoogleCastManager: BCOVPlaybackSessionConsumer {

    func didAdvance(to session: BCOVPlaybackSession!) {
        createMediaInfo(fromVideo: session.video)
        setupRemoteMediaClientWithMediaInfo()
    }

    func playbackSession(_ session: BCOVPlaybackSession!,
                         didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if let _ = GCKCastContext.sharedInstance().sessionManager.currentSession {

            if kBCOVPlaybackSessionLifecycleEventReady == lifecycleEvent.eventType {
                switchToRemotePlayback()
            }
        }
    }

    func playbackSession(_ session: BCOVPlaybackSession!,
                         didProgressTo progress: TimeInterval) {
        currentProgress = progress
    }

}


// MARK: - GCKSessionManagerListener

extension GoogleCastManager: GCKSessionManagerListener {

    func sessionManager(_ sessionManager: GCKSessionManager,
                        didStart session: GCKSession) {
        switchToRemotePlayback()
        setupRemoteMediaClientWithMediaInfo()
    }

    func sessionManager(_ sessionManager: GCKSessionManager,
                        didResumeSession session: GCKSession) {
        switchToRemotePlayback()
    }

    func sessionManager(_ sessionManager: GCKSessionManager,
                        didEnd session: GCKSession,
                        withError error: Error?) {
        switchToLocalPlayback(withError: error)
    }

    func sessionManager(_ sessionManager: GCKSessionManager,
                        didFailToStart session: GCKSession,
                        withError error: Error) {
        switchToLocalPlayback(withError: error)
    }
}


// MARK: - GCKUIMediaControllerDelegate

extension GoogleCastManager: GCKUIMediaControllerDelegate {

    func mediaController(_ mediaController: GCKUIMediaController,
                         didUpdate mediaStatus: GCKMediaStatus) {

        // Once the video has finished, let the delegate know
        // and attempt to proceed to the next session, if autoAdvance
        // is enabled
        if mediaStatus.idleReason == .finished {
            currentVideo = nil

            delegate?.castedVideoDidComplete()

            if let playbackController = delegate?.playbackController {
                if playbackController.isAutoAdvance {
                    playbackController.advanceToNext()
                }
            }
        }

        if mediaStatus.idleReason == .error {
            currentVideo = nil

            delegate?.castedVideoFailedToPlay()
        }

        castStreamPosition = mediaStatus.streamPosition
    }
}
