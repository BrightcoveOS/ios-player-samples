//
//  CustomSliderView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK

struct CustomSliderView: UIViewRepresentable {
    typealias UIViewType = BCOVPUISlider
    typealias SliderCompletionHandler = (Float) -> Void

    @EnvironmentObject var playerModel: PlayerModel
    @Binding var value: Double
    let onValueChanged: SliderCompletionHandler?

    init(value: Binding<Double>, onValueChanged: SliderCompletionHandler? = nil) {
        _value = value
        self.onValueChanged = onValueChanged
    }

    func makeUIView(context: Context) -> BCOVPUISlider {
        let slider = BCOVPUISlider(frame: .zero)
        slider.value = Float(0)
        slider.minimumValue = .zero
        slider.maximumValue = Float(playerModel.duration)
        slider.addTarget(context.coordinator, action: #selector(CustomSliderViewCoordinator.valueChanged(_:)), for: .valueChanged)
        return slider
    }

    func updateUIView(_ slider: BCOVPUISlider, context: Context) {
        slider.value = Float(value)
        slider.maximumValue = Float(playerModel.duration)
        slider.bufferProgress = Float(playerModel.buffer)
    }

    func makeCoordinator() -> CustomSliderViewCoordinator {
        CustomSliderViewCoordinator(value: $value, buffer: $playerModel.buffer, onValueChanged: onValueChanged)
    }


    // MARK: -

    final class CustomSliderViewCoordinator: NSObject {

        private(set) var value: Binding<Double>
        private(set) var buffer: Binding<Double>
        let onValueChanged: SliderCompletionHandler?

        init(value: Binding<Double>, buffer: Binding<Double>, onValueChanged: SliderCompletionHandler? = nil) {
            self.value = value
            self.buffer = buffer
            self.onValueChanged = onValueChanged
        }

        @objc
        func valueChanged(_ sender: BCOVPUISlider) {
            self.value.wrappedValue = Double(sender.value)
            self.buffer.wrappedValue = Double(sender.bufferProgress)
            onValueChanged?(sender.value)
        }
    }
}


// MARK: -

#if DEBUG
struct CustomSliderView_Previews: PreviewProvider {
    static var previews: some View {
        CustomSliderView(value: .constant(0))
            .environmentObject(PlayerModel())
    }
}
#endif
