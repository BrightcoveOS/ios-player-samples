//
//  WatchTogetherWrapper.swift
//  SharePlayPlayer
//
//  Created by Jeremy Blaker on 6/29/21.
//

import Foundation
import BrightcovePlayerSDK
import GroupActivities
import Combine

protocol WatchTogetherWrapperDelegate: NSObject {
    func groupSessionWasJoined()
    func groupSessionWasInvalidated()
    func activityWasDisabled()
    func activityWasActivated()
    func activityFailedActivation()
}

class WatchTogetherWrapper: NSObject {
    
    public weak var player: AVPlayer? {
        didSet {
            guard let session = groupSession else {
                return
            }
            // Coordinate playback with the active session.
            player?.playbackCoordinator.coordinateWithSession(session)
        }
    }
    weak var delegate: WatchTogetherWrapperDelegate?
    public weak var playbackController: BCOVPlaybackController?

    private var subscriptions = [AnyCancellable]()
    private var watchTogether: WatchTogether?
    private var result: GroupActivityActivationResult?
    private var groupSession: GroupSession<WatchTogether>? {
        didSet {
            guard let session = groupSession else {
                // Stop playback if a session terminates.
                player?.rate = 0
                return
            }
            // Coordinate playback with the active session.
            player?.playbackCoordinator.coordinateWithSession(session)
        }
    }
    
    override init() {
        super.init()
        startListening()
    }
    
    func activateNewActivity(withVideo video: BCOVVideo, withSource source: BCOVSource) {
        
        let movieTitle = video.properties[kBCOVVideoPropertyKeyName] as? String ?? "<Title Unavailable>"

        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.title = movieTitle
        
        var keySystems: [String:[String:String]]?
        
        if let _keySystems = source.properties["key_systems"] as? [String:[String:String]] {
            keySystems = _keySystems
        }
        
        watchTogether = WatchTogether(metadata: metadata, sourceURL: source.url.absoluteString, keySystems: keySystems)

        guard let watchTogether = watchTogether else {
            return
        }
        
        Task {
            let result = await watchTogether.prepareForActivation()
            switch result {
            case .activationPreferred:
                let didActivate = try await watchTogether.activate()
                if didActivate {
                    delegate?.activityWasActivated()
                } else {
                    delegate?.activityFailedActivation()
                }
                return
            case .activationDisabled:
                delegate?.activityWasDisabled()
                return
            default:
                return
            }
        }
    }

    func endSharePlay() {
        if let _groupSession = groupSession {
            _groupSession.end()
            groupSession = nil
        }
    }
        
    func startListening() {
        Task.init(priority: TaskPriority.background) {
            for await groupSession in WatchTogether.sessions() {
                // Set the app's active group session.
                self.groupSession = groupSession
                
                // Remove previous subscriptions.
                subscriptions.removeAll()

                // Observe changes to the session state.
                groupSession.$state.sink { [weak self] state in
                    if case .invalidated = state {
                        // Set the groupSession to nil to publish
                        // the invalidated session state.
                        self?.groupSession = nil
                        self?.subscriptions.removeAll()
                        self?.delegate?.groupSessionWasInvalidated()
                    }
                    
                    if case .waiting = state {
                        // Join the session to participate in playback coordination.
                        groupSession.join()
                    }
                    
                    if case .joined = state {
                        self?.delegate?.groupSessionWasJoined()
                    }
                }.store(in: &subscriptions)

                
                // Observe when the local user or a remote participant starts an activity.
                groupSession.$activity.sink { [weak self] activity in

                    if let sourceURL = URL(string: activity.sourceURL) {
                        
                        var sourceProperties = [AnyHashable:AnyHashable]()
                        
                        if let keySystems = activity.keySystems {
                            sourceProperties["key_systems"] = keySystems
                        }
                                                
                        let source = BCOVSource(url: sourceURL, deliveryMethod: kBCOVSourceDeliveryHLS, properties: sourceProperties)
                        
                        let video = BCOVVideo(source: source, cuePoints: nil, properties: nil)
                        
                        if let _playbackController = self?.playbackController {
                            DispatchQueue.main.async {
                                _playbackController.setVideos([video] as NSFastEnumeration)
                            }
                        }

                    }
                    
                }.store(in: &subscriptions)
            }
        }
    }
    
}

extension WatchTogetherWrapper: BCOVPlaybackSessionConsumer {
    func didAdvance(to session: BCOVPlaybackSession!) {
        self.player = session.player
    }
}

