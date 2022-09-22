//
//  SliderBrightCoveSwiftUIView.swift
//  SwiftUIPlayer
//
//  Created by Lê Quang Trọng Tài on 9/22/22.
//

import BrightcovePlayerSDK
import Foundation
import SwiftUI

struct SliderBrightCoveSwiftUIView: UIViewRepresentable {
    @Binding var value: Double
    @Binding var buffer: Double
    @Binding var duration: Double
    var onValueChange: (Float) -> Void?

    func makeUIView(context: Context) -> BCOVPUISlider {
        let slider = BCOVPUISlider(frame: .zero)
        slider.value = Float(value)
        slider.minimumValue = .zero
        slider.maximumValue = Float(duration)
        slider.addTarget(
            context.coordinator, action: #selector(Coordinator.onValueChanged(_:)),
            for: .valueChanged)
        return slider
    }

    func updateUIView(_ uiView: BCOVPUISlider, context: Context) {
        uiView.value = Float(self.value)
        uiView.maximumValue = Float(self.duration)
        uiView.bufferProgress = Float(self.buffer)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, buffer: $buffer, onValueChanged: onValueChange)
    }

    //MARK: Coordinator
    class Coordinator: NSObject {
        var value: Binding<Double>
        var buffer: Binding<Double>
        var onValueChange: (Float) -> Void?

        init(
            value: Binding<Double>, buffer: Binding<Double>,
            onValueChanged: @escaping (Float) -> Void?
        ) {
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
