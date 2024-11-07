//
//  BCOVFlutterPlugin.swift
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import Flutter


final class BCOVFlutterPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(BCOVVideoPlayerFactory(), withId: "bcov.flutter/player_view")
    }
}
