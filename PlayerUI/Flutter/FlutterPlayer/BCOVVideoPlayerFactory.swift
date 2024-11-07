//
//  BCOVVideoPlayerFactory.swift
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import Flutter
import BrightcovePlayerSDK


final class BCOVVideoPlayerFactory: NSObject, FlutterPlatformViewFactory {

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        return BCOVVideoPlayer(frame: frame,
                               viewId: viewId,
                               args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
