//
//  CustomSliderView.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI
import BrightcovePlayerSDK


struct CustomSliderView<ThumbnailView: View>: UIViewRepresentable {
    typealias UIViewType = BCOVPUISlider
    typealias ThumbnailVideoView = UIViewController
    typealias SliderCompletionHandler = (Float) -> Void
    typealias SliderTouchHandler = (CGPoint, CGRect, Bool) -> Void

    @EnvironmentObject
    var playerModel: PlayerModel

    let thumbnailView: ThumbnailVideoView
    let onTouchSliderEvent: SliderTouchHandler?
    let onValueChanged: SliderCompletionHandler?

    init(@ViewBuilder content: @escaping () -> ThumbnailView,
         onValueChanged: SliderCompletionHandler? = nil,
         onTouchSliderEvent: SliderTouchHandler? = nil) {
        thumbnailView = UIHostingController(rootView: content())
        self.onTouchSliderEvent = onTouchSliderEvent
        self.onValueChanged = onValueChanged
    }

    func makeUIView(context: Context) -> BCOVPUISlider {
        let slider = BCOVPUISlider(frame: .zero)
        slider.value = Float(0)
        slider.minimumValue = .zero
        slider.maximumValue = Float(playerModel.duration)
        slider.addTarget(context.coordinator,
                         action: #selector(CustomSliderViewCoordinator.valueChanged(_:)),
                         for: .valueChanged)

        thumbnailView.view.backgroundColor = .clear
        slider.addSubview(thumbnailView.view)
        slider.addTarget(context.coordinator,
                         action: #selector(CustomSliderViewCoordinator.sliderOnTouchEvent),
                         for: .allTouchEvents)

        return slider
    }

    func updateUIView(_ slider: BCOVPUISlider, context: Context) {
        slider.value = Float(playerModel.progress)
        slider.maximumValue = Float(playerModel.duration)
        slider.bufferProgress = Float(playerModel.buffer)
    }

    func makeCoordinator() -> CustomSliderViewCoordinator {
        CustomSliderViewCoordinator(self)
    }


    // MARK: - CustomSliderViewCoordinator

    final class CustomSliderViewCoordinator: NSObject {

        let parent: CustomSliderView

        init(_ parent: CustomSliderView) {
            self.parent = parent
        }

        @objc
        func valueChanged(_ sender: BCOVPUISlider) {
            parent.playerModel.progress = Double(sender.value)
            parent.playerModel.buffer = Double(sender.bufferProgress)
            parent.thumbnailView.view.center = CGPoint(
                x: sender.thumbBounds.midX,
                y: sender.thumbBounds.minY - (parent.thumbnailView.view.frame.height / 2) - 32
            )

            guard let onValueChanged = parent.onValueChanged else { return }
            onValueChanged(sender.value)
        }

        @objc
        func sliderOnTouchEvent(sender: BCOVPUISlider,
                                event: UIEvent) {
            guard let onTouchSliderEvent = parent.onTouchSliderEvent,
                  let touchEvent = event.allTouches?.first else { return }

            switch touchEvent.phase {
                case .began,
                        .moved,
                        .ended:
                    onTouchSliderEvent(touchEvent.location(in:  sender),
                                       sender.thumbFrame,
                                       sender.isTracking)

                default:
                    break
            }
        }
    }
}


// MARK: -

#if DEBUG
struct CustomSliderView_Previews: PreviewProvider {
    static var previews: some View {
        CustomSliderView {
            ThumbnailView()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: 100, height: 60)
        }
        .environmentObject(PlayerModel())
    }
}
#endif
