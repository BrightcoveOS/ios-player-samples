//
//  ContentView.swift
//  SwiftUIPlayer
//
//  Created by Carlos Ceja.
//

import BrightcovePlayerSDK
import SwiftUI

struct Constants {
    static let AccountID = "5434391461001"
    static let PolicyKey =
        "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let VideoId = "5702141808001"
}

struct ContentView: View {
    @State var duration = Double.zero
    @State var bufffer = Double.zero
    @State var progress = Double.zero

    var playbackController: BCOVPlaybackController = {
        let fairPlayAuthProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil)!
        let basicSessionProvider = BCOVPlayerSDKManager.sharedManager()?.createBasicSessionProvider(
            with: nil)
        let fairplaySessionProvider = BCOVPlayerSDKManager.sharedManager()?
            .createFairPlaySessionProvider(
                withApplicationCertificate: nil, authorizationProxy: fairPlayAuthProxy,
                upstreamSessionProvider: basicSessionProvider)
        let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(
            with: fairplaySessionProvider, viewStrategy: nil)
        _playbackController?.isAutoPlay = true
        _playbackController?.isAutoAdvance = true

        return _playbackController!

    }()

    var playerView: BCOVPUIPlayerView = {

        let options = BCOVPUIPlayerViewOptions()
        options.automaticControlTypeSelection = false  // We don't using basic control view.

        return BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: nil)

    }()

    var body: some View {
        VStack {
            Text("Brightcove Player SwiftUI")
                .bold()
            ZStack {
                PlayerUI(
                    self.playbackController,
                    self.playerView,
                    duration: $duration,
                    bufffer: $bufffer,
                    progress: $progress
                )
                .aspectRatio(16 / 9, contentMode: .fit)
                .onAppear {
                    let playbackService = BCOVPlaybackService(
                        accountId: Constants.AccountID, policyKey: Constants.PolicyKey)

                    playbackService?.findVideo(
                        withVideoID: Constants.VideoId, parameters: nil,
                        completion: {
                            (
                                video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?,
                                error: Error?
                            ) in

                            if let video = video {
                                self.playbackController.setVideos([video] as NSFastEnumeration)
                            } else {
                                print(
                                    "ContentView Debug - Error retrieving video: \(error!.localizedDescription)"
                                )
                            }
                        })
                }
                WrapperView()
            }
        }
    }
}

struct WrapperView: View {
    var body: some View {
        Text("Wrraper View")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
