//
//  BCOVVideoPlayerManager.swift
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import React

@objc(BCOVVideoPlayerManager)
final class BCOVVideoPlayerManager: RCTViewManager {

    @objc
    override func view() -> UIView {
        return BCOVVideoPlayer()
    }
}
