//
//  BCOVVideoPlayer.swift
//  PlayerFlutter
//
//  Created by Carlos Ceja.
//

import AVFoundation
import AVKit
import Foundation

import BrightcovePlayerSDK
import Flutter


class BCOVVideoPlayer: NSObject {
    
    private var viewId: Int64
    
    lazy private var player: AVPlayer = {
        var _player = AVPlayer()
        return _player
    }()
    
    lazy private var avpvc: AVPlayerViewController = {
        var _avpvc = AVPlayerViewController()
        _avpvc.player = self.player
        _avpvc.showsPlaybackControls = false
        return _avpvc
    }()
    
    private var eventSink: FlutterEventSink?
    
    private var eventChannel: FlutterEventChannel!
    private var methodChannel: FlutterMethodChannel!
    
    lazy private var manager: BCOVPlayerSDKManager = {
        let _manager = BCOVPlayerSDKManager.shared()!
        return _manager
    }()
    
    private var playbackService: BCOVPlaybackService!
    private var playbackController: BCOVPlaybackController!
    
    init(frame:CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        self.viewId = viewId
        
        super.init()
        
        self.avpvc.view.frame = frame
        
        self.setupEventChannel(withViewIdentifier: viewId, messenger: messenger, instance: self)
        self.setupMethodChannel(withViewIdentifier: viewId, messenger: messenger, instance: self)
        
        let rootController = UIApplication.shared.delegate?.window??.rootViewController
        rootController?.addChild(self.avpvc)
        
        /* data as JSON */
        let parsedData = args as! [String: Any]
        
        let playbackControllerArgs = parsedData["playbackController"] as! [String: Any]
        let autoPlay = playbackControllerArgs["autoPlay"] as! Bool
        let autoAdvance = playbackControllerArgs["autoAdvance"] as! Bool
        self.playbackController = self.manager.createPlaybackController()!
        self.playbackController.delegate = self
        self.playbackController.isAutoPlay = autoPlay
        self.playbackController.isAutoAdvance = autoAdvance
        self.playbackController.options = [kBCOVAVPlayerViewControllerCompatibilityKey: true]
        
        let playbackServiceArgs = parsedData["playbackService"] as! [String: Any]
        let accountId = playbackServiceArgs["accountId"] as! String
        let policyKey = playbackServiceArgs["policyKey"] as! String
        self.playbackService = BCOVPlaybackService(accountId: accountId, policyKey: policyKey)
    }
    
    private func setupEventChannel(withViewIdentifier viewId: Int64, messenger:FlutterBinaryMessenger, instance: BCOVVideoPlayer) {
        // register for Flutter event channel
        let eventChannelName = String(format: "bcov.flutter/event_channel_%lld", viewId)
        instance.eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger, codec: FlutterJSONMethodCodec.sharedInstance())
        instance.eventChannel.setStreamHandler(instance)
    }
    
    private func setupMethodChannel(withViewIdentifier viewId: Int64, messenger:FlutterBinaryMessenger, instance: BCOVVideoPlayer) {
        // register for Flutter method channel
        let methodChannelName = String(format: "bcov.flutter/method_channel_%lld", viewId)
        instance.methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
        instance.methodChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            self?.handle(call, result: result)
        })
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if "setVideo" == call.method {
            /* data as JSON */
            let parsedData = call.arguments as! [String: Any]
            
            let videoId = parsedData["videoId"] as! String
            let authToken = parsedData["authToken"] as? String
            let parameters = parsedData["parameters"] as? [AnyHashable : Any]
            
            var configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:videoId]
            if authToken != nil {
                configuration[kBCOVPlaybackServiceConfigurationKeyAuthToken] = authToken
            }
            playbackService?.findVideo(withConfiguration: configuration, queryParameters: parameters, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
                
                if let video = video {
                    self?.playbackController.setVideos([video] as NSFastEnumeration)
                }
                else {
                    self?.eventSink?(["name": "onError"])
                }
                result(true)
            })
        }
        else if "play" == call.method {
            self.playbackController.play()
        }
        else if "pause" == call.method {
            self.playbackController.pause()
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
}

extension BCOVVideoPlayer: FlutterPlatformView {
    
    func view() -> UIView {
        return self.avpvc.view
    }
}

extension BCOVVideoPlayer: FlutterStreamHandler {
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

extension BCOVVideoPlayer: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        self.player = session.player
        self.avpvc.player = session.player
        
        let duration = session.video.properties["duration"] as! Double
        self.eventSink?(["name": "didAdvanceToPlaybackSession", "duration": duration, "isPlaying": self.playbackController.isAutoPlay])
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        if !progress.isInfinite {
            self.eventSink?(["name": "didProgressTo", "progress": (progress * 1000)])
        }
    }
}


class BCOVVideoPlayerFactory: NSObject {
    
    private var registar: FlutterPluginRegistrar
    private var messenger: FlutterBinaryMessenger
    
    init(registrar: FlutterPluginRegistrar) {
        self.registar = registrar
        self.messenger = registrar.messenger()
        super.init()
    }
    
}

extension BCOVVideoPlayerFactory: FlutterPlatformViewFactory {
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return BCOVVideoPlayer(frame: frame, viewId: viewId, messenger: self.messenger, args: args)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
