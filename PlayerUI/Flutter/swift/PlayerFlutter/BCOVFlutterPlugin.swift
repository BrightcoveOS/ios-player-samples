//
//  BCOVFlutterPlugin.swift
//  PlayerFlutter
//
//  Created by Carlos Ceja.
//

import Foundation

import Flutter


class BCOVFlutterPlugin : NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = BCOVVideoPlayerFactory(registrar: registrar)
        registrar.register(factory, withId: "bcov.flutter/player_view")
    }

}
