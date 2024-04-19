//
//  ControlViewStyles.swift
//  PlayerUICustomization
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


final class ControlViewStyles: NSObject {

    class func Simple(forControlsView controlsView: BCOVPUIBasicControlView) {
        // Customize the font for the play/pause button
        // This font is registered in Info.plist

        if let playbackButton = controlsView.playbackButton,
           let fontello = UIFont(name: "fontello", size: 20) {
            playbackButton.titleLabel?.font = fontello
            playbackButton.primaryTitle = "\u{e801}"
            playbackButton.secondaryTitle = "\u{e802}"
            playbackButton.showPrimaryTitle(true)
        }

        // Alternatively you can customize a single-state button
        // with an image instead
        if let ccButton = controlsView.closedCaptionButton,
           let iconImage = UIImage(named: "captions.bubble") {
            ccButton.primaryTitle = ""
            ccButton.secondaryTitle = ""
            ccButton.showPrimaryTitle(true)
            ccButton.setImage(iconImage, for: .normal)
            ccButton.tintColor = .white
            ccButton.backgroundColor = .clear
        }
    }

    class func Complex(forControlsView controlsView: BCOVPUIBasicControlView) {

        if let font = UIFont(name: "Courier", size: 16) {
            controlsView.currentTimeLabel.font = font
            controlsView.currentTimeLabel.textColor = .orange

            controlsView.durationLabel.font = font
            controlsView.durationLabel.textColor = .orange

            controlsView.timeSeparatorLabel.font = font
            controlsView.timeSeparatorLabel.textColor = .green
        }

        // Change color of play/pause button.
        if let playbackButton = controlsView.playbackButton {
            playbackButton.setTitleColor(.orange, for: .normal)
            playbackButton.setTitleColor(.yellow, for: .highlighted)
        }

        // Change color of jump back button.
        if let jumpBackButton = controlsView.jumpBackButton {
            jumpBackButton.setTitleColor(.orange, for: .normal)
            jumpBackButton.setTitleColor(.yellow, for: .highlighted)
        }

        // Change color of full-screen button.
        if let screenModeButton = controlsView.screenModeButton {
            screenModeButton.setTitleColor(.orange, for: .normal)
            screenModeButton.setTitleColor(.yellow, for: .highlighted)
        }

        // Change color of closed-captions button.
        if let closedCaptionButton = controlsView.closedCaptionButton {
            closedCaptionButton.setTitleColor(.orange, for: .normal)
            closedCaptionButton.setTitleColor(.yellow, for: .highlighted)
        }

        // Customize the slider
        if let slider = controlsView.progressSlider {
            slider.bufferProgressTintColor = .green
            slider.minimumTrackTintColor = .orange
            slider.maximumTrackTintColor = .purple
            slider.thumbTintColor = UIColor(red: 0.9, green: 0.3,
                                            blue: 0.3, alpha: 0.5)

            // Add markers to the slider for your own use
            slider.markerTickColor = .lightGray
            slider.addMarker(at: 30, duration: 0.0, isAd: false, image: nil)
            slider.addMarker(at: 60, duration: 0.0, isAd: false, image: nil)
            slider.addMarker(at: 90, duration: 0.0, isAd: false, image: nil)
        }
    }
}
