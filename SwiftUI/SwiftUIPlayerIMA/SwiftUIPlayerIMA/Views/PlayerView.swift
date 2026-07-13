//
//  PlayerView.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import SwiftUI

struct PlayerView: View {

    @State private var viewModel: PlayerViewModel

    init(adMode: AdMode) {
        _viewModel = State(initialValue: PlayerViewModel(adMode: adMode))
    }

    var body: some View {
        VStack(spacing: 0) {
            BCOVPlayerRepresentable(viewModel: viewModel)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .background(Color.black)

            Form {
                Section {
                    ForEach(Config.demoVideos) { video in
                        Button {
                            guard viewModel.currentVideoID != video.id else { return }
                            viewModel.load(videoID: video.id)
                        } label: {
                            HStack {
                                Text(video.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.currentVideoID == video.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("Now playing")
                } footer: {
                    Text("Switching videos uses the same playback controller — the IMA chain stays wired for \(viewModel.adMode.displayName) ads.")
                }

                Section("Status") {
                    statusRow
                }

                Section {
                    CompanionAdSlotView(viewModel: viewModel)
                        .frame(width: 300, height: 250)
                        .frame(maxWidth: .infinity, alignment: .center)
                } header: {
                    Text("Companion ad slot")
                } footer: {
                    Text("IMA renders any companion creatives the ad server returns into this 300×250 view.")
                }
            }
        }
        .navigationTitle(viewModel.adMode.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var statusRow: some View {
        switch viewModel.status {
        case .idle:
            Label("Idle", systemImage: "pause.circle")
        case .loading:
            Label("Loading…", systemImage: "arrow.triangle.2.circlepath")
        case .ready:
            Label(viewModel.isInAdSequence ? "Playing ad" : "Ready",
                  systemImage: viewModel.isInAdSequence ? "play.rectangle" : "play.circle")
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }
}

/// Hosts the companion-ad UIView owned by the view model. The same UIView is
/// also wired into `IMACompanionAdSlot` from `IMAPlayerViewController`; IMA
/// renders companion creatives directly into it.
private struct CompanionAdSlotView: UIViewRepresentable {
    let viewModel: PlayerViewModel

    func makeUIView(context: Context) -> UIView { viewModel.companionView }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
