//
//  PlayerUIView.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Combine
import SwiftUI
import BrightcovePlayerSDK


struct PlayerUIView: View {

    @StateObject
    fileprivate var playerModel = PlayerModel()

    @State
    fileprivate var cancellables = [AnyCancellable]()

    @State
    fileprivate var showAlert = false

#if targetEnvironment(simulator)
    @State
    fileprivate var showFairPlayWarning = false
#endif

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                VideoContainerView(view: playerModel.playbackController?.view)
                playerModel.contentOverlayViewContainer
                CustomControlsView()
                    .environmentObject(playerModel)
                    .opacity(playerModel.showControls ? 1.0 : 0.0)
                    .animation(.easeInOut,
                               value: playerModel.showControls)
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .onTapGesture {
            if !playerModel.inAdSequence {
                playerModel.showControls = !playerModel.showControls
            }
        }
        .onAppear {
            let videoModel = VideoModel()
            videoModel.requestContentFromPlaybackService()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            showAlert.toggle()
                            print("VideoModel - Error retrieving video: \(error.localizedDescription)")
                    }
                }, receiveValue: { video in
                    guard let playbackController = playerModel.playbackController else { return }
#if targetEnvironment(simulator)
                    if video.usesFairPlay {
                        showFairPlayWarning.toggle()
                        return
                    }
#endif
                    if playbackController.thumbnailSeekingEnabled {
                        handleThumbnails(for: video)
                    }

                    playbackController.setVideos([video] as NSFastEnumeration)
                })
                .store(in: &cancellables)
        }
        .alert(isPresented: $showAlert) { () -> Alert in
            Alert(title: Text("SwiftUICustomControls"),
                  message: Text("Error retrieving video."),
                  dismissButton: .default(Text("Ok")))
        }
#if targetEnvironment(simulator)
        .alert(isPresented: $showFairPlayWarning) { () -> Alert in
            Alert(title: Text("FairPlay Warning"),
                  message: Text("FairPlay only works on actual iOS or tvOS devices.\n\nYou will not be able to view any FairPlay content in the iOS or tvOS simulator."),
                  dismissButton: .default(Text("Ok")))
        }
#endif
    }
}


private extension PlayerUIView {

    func handleThumbnails(for video: BCOVVideo) {
        if let textTracks = video.properties[kBCOVVideoPropertyKeyTextTracks] as? [[String: Any]] {
            for track in textTracks {
                if let trackLabel = track["label"] as? String,
                   trackLabel == "thumbnails" {
                    if let trackSrc = track["src"] as? String {
                        if trackSrc.hasPrefix("https://") {
                            if let httpsThumbnailURL = URL(string: trackSrc) {
                                playerModel.thumbnailManager = ThumbnailManager(url: httpsThumbnailURL)
                                break
                            }
                        } else if trackSrc.hasPrefix("http://") {
                            if let httpThumbnailURL = URL(string: trackSrc) {
                                playerModel.thumbnailManager = ThumbnailManager(url: httpThumbnailURL)
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}


// MARK: -

#if DEBUG
struct PlayerUIView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerUIView()
    }
}
#endif
