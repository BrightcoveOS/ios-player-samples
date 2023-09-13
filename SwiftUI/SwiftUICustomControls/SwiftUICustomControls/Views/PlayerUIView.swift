//
//  PlayerUIView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Combine
import SwiftUI


struct PlayerUIView: View {

    @StateObject private var playerModel = PlayerModel()
    @State private var cancellables = [AnyCancellable]()
    @State private var showAlert = false

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                VideoView(view: playerModel.controller?.view)
                CustomControlsView()
                    .environmentObject(playerModel)
                    .opacity(playerModel.showControls ? 1.0 : 0.0)
                    .animation(.easeInOut, value: playerModel.showControls)
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .onTapGesture {
            playerModel.showControls = !playerModel.showControls
        }
        .onAppear {
            let videoModel = VideoModel()
            videoModel.requestVideo()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        showAlert.toggle()
                        print("VideoModel Debug - Error retrieving video: \(error.localizedDescription)")
                    }
                }, receiveValue: { video in
                    playerModel.controller?.setVideos([video] as NSFastEnumeration)
                })
                .store(in: &cancellables)
        }
        .alert(isPresented: $showAlert) { () -> Alert in
            Alert(title: Text("SwiftUICustomControls"), message: Text("Error retrieving video."), dismissButton: .cancel())
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
