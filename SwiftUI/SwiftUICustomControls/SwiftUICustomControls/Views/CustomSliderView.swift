//
//  CustomSliderView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import BrightcovePlayerSDK
import Foundation
import SwiftUI

struct CustomSliderView: UIViewRepresentable {
    @Binding var value: Double
    @EnvironmentObject var playerStateModelData: PlayerStateModelData
    var onValueChange: (Float) -> Void?

    func makeUIView(context: Context) -> BCOVPUISlider {
        let slider = BCOVPUISlider(frame: .zero)
        slider.value = Float(value)
        slider.minimumValue = .zero
        slider.maximumValue = Float(playerStateModelData.duration)
        slider.addTarget(
            context.coordinator, action: #selector(Coordinator.onValueChanged(_:)),
            for: .valueChanged)
        return slider
    }

    func updateUIView(_ uiView: BCOVPUISlider, context: Context) {
        uiView.value = Float(self.value)
        uiView.maximumValue = Float(playerStateModelData.duration)
        uiView.bufferProgress = Float(playerStateModelData.buffer)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, buffer: $playerStateModelData.buffer, onValueChanged: onValueChange)
    }

    //MARK: Coordinator
    class Coordinator: NSObject {
        var value: Binding<Double>
        var buffer: Binding<Double>
        var onValueChange: (Float) -> Void?

        init(value: Binding<Double>, buffer: Binding<Double>, onValueChanged: @escaping (Float) -> Void?) {
            self.value = value
            self.buffer = buffer
            self.onValueChange = onValueChanged
        }

        @objc
        func onValueChanged(_ sender: BCOVPUISlider) {
            self.value.wrappedValue = Double(sender.value)
            self.buffer.wrappedValue = Double(sender.bufferProgress)
            onValueChange(sender.value)
        }
    }
    typealias UIViewType = BCOVPUISlider
}
