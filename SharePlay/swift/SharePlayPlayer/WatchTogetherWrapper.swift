//
//  WatchTogetherWrapper.swift
//  SharePlayPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Combine
import Foundation
import GroupActivities
import BrightcovePlayerSDK


protocol WatchTogetherWrapperDelegate: NSObject {
    func groupSessionWasJoined()
    func groupSessionWasInvalidated()
    func activityWasDisabled()
    func activityWasActivated()
    func activityFailedActivation()
}


final class WatchTogetherWrapper: NSObject {

    weak var player: AVPlayer? {
        didSet {
            guard let groupSession else {
                return
            }

            // Coordinate playback with the active session.
            player?.playbackCoordinator.coordinateWithSession(groupSession)
        }
    }

    weak var delegate: WatchTogetherWrapperDelegate?
    weak var playbackController: BCOVPlaybackController?

    fileprivate var subscriptions = [AnyCancellable]()
    fileprivate var watchTogether: WatchTogether?
    fileprivate var result: GroupActivityActivationResult?
    fileprivate var groupSession: GroupSession<WatchTogether>? {
        didSet {
            guard let groupSession else {
                // Stop playback if a session terminates.
                player?.rate = 0
                return
            }

            // Coordinate playback with the active session.
            player?.playbackCoordinator.coordinateWithSession(groupSession)
        }
    }

    override init() {
        super.init()
        startListening()
    }

    func activateNewActivity(withVideo video: BCOVVideo,
                             withSource source: BCOVSource) {

        let movieTitle = video.properties[BCOVVideo.PropertyKeyName] as? String ?? "<Title Unavailable>"

        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.title = movieTitle

        let keySystems = source.properties["key_systems"] as? [String: [String: String]]
        
        guard let sourceURL = source.url else {
            return
        }

        watchTogether = WatchTogether(metadata: metadata,
                                      sourceURL: sourceURL.absoluteString,
                                      keySystems: keySystems)

        guard let watchTogether else {
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
                    break
                case .activationDisabled:
                    delegate?.activityWasDisabled()
                    break
                default:
                    break
            }
        }
    }

    func endSharePlay() {
        if let groupSession {
            groupSession.end()
        }
    }

    fileprivate func startListening() {
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
                groupSession.$activity.sink { [playbackController] activity in

                    if let sourceURL = URL(string: activity.sourceURL) {

                        var sourceProperties = [AnyHashable:AnyHashable]()

                        if let keySystems = activity.keySystems {
                            sourceProperties["key_systems"] = keySystems
                        }

                        let source = BCOVSource(withURL: sourceURL,
                                                deliveryMethod: BCOVSource.DeliveryHLS,
                                                properties: sourceProperties)

                        let video = BCOVVideo(withSource: source,
                                              cuePoints: nil,
                                              properties: nil)

                        if let playbackController {
                            DispatchQueue.main.async {
                                playbackController.setVideos([video])
                            }
                        }

                    }

                }.store(in: &subscriptions)
            }
        }
    }
}


// MARK: - BCOVPlaybackSessionConsumer

extension WatchTogetherWrapper: BCOVPlaybackSessionConsumer {

    func didAdvance(to session: BCOVPlaybackSession!) {
        player = session.player
    }

}
