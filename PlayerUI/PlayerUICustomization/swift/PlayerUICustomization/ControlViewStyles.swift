//
//  ControlViewStyles.swift
//  PlayerUICustomization
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

class ControlViewStyles: NSObject {
    
    class func Complex(forControlsView controlsView: BCOVPUIBasicControlView) {
        
        let font = UIFont(name: "Courier", size: 18)
        
        controlsView.currentTimeLabel.font = font
        controlsView.currentTimeLabel.textColor = .orange
        controlsView.durationLabel.font = font
        controlsView.durationLabel.textColor = .orange
        controlsView.timeSeparatorLabel.font = font
        controlsView.timeSeparatorLabel.textColor = .green
        
        // Change color of full-screen button.
        controlsView.screenModeButton?.setTitleColor(.orange, for: .normal)
        controlsView.screenModeButton?.setTitleColor(.yellow, for: .highlighted)
        
        // Change color of jump back button.
        controlsView.jumpBackButton?.setTitleColor(.orange, for: .normal)
        controlsView.jumpBackButton?.setTitleColor(.yellow, for: .highlighted)
        
        // Change color of play/pause button.
        controlsView.playbackButton?.setTitleColor(.orange, for: .normal)
        controlsView.playbackButton?.setTitleColor(.yellow, for: .highlighted)
        
        // Customize the slider
        let slider = controlsView.progressSlider
        slider?.bufferProgressTintColor = .green
        slider?.minimumTrackTintColor = .orange
        slider?.maximumTrackTintColor = .purple
        slider?.thumbTintColor = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.5)
        
        // Add markers to the slider for your own use
        slider?.markerTickColor = .lightGray
        slider?.addMarker(at: 30, duration: 0.0, isAd: false, image: nil)
        slider?.addMarker(at: 60, duration: 0.0, isAd: false, image: nil)
        slider?.addMarker(at: 90, duration: 0.0, isAd: false, image: nil)
        
    }

}
