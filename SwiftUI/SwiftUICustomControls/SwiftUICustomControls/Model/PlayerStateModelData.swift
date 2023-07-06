//
//  PlayerStateModelData.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import Foundation

class PlayerStateModelData: ObservableObject {
    @Published var duration: Double = Double.zero
    @Published var buffer: Double = Double.zero
    @Published var progress: Double = Double.zero
    @Published var isPlaying: Bool = false
}
