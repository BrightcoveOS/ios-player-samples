//
//  BCOVVideoPlayer.m
//  PlayerFlutter
//
//  Created by Carlos Ceja.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVVideoPlayer.h"


@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate>

@end

@implementation BCOVVideoPlayer
{
    int64_t _viewId;
    
    AVPlayer *_player;
    AVPlayerViewController *_avpvc;
    
    FlutterEventSink _eventSink;
    
    FlutterEventChannel *_eventChannel;
    FlutterMethodChannel *_methodChannel;
    
    BCOVPlayerSDKManager *_manager;
    BCOVPlaybackService *_playbackService;
    id<BCOVPlaybackController> _playbackController;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger
{
    if (self = [super init])
    {
        _viewId = viewId;
        
        _player = [[AVPlayer alloc] init];
        
        _avpvc = ({
            AVPlayerViewController *avpvc = [[AVPlayerViewController alloc] init];
            avpvc.view.frame = frame;
            avpvc.player = _player;
            avpvc.showsPlaybackControls = NO;
            avpvc;
        });
        
        [self setupEventChannelWithViewIdentifier:viewId messenger:messenger instance:self];
        [self setupMethodChannelWithViewIdentifier:viewId messenger:messenger instance:self];
        
        UIViewController *rootController = UIApplication.sharedApplication.delegate.window.rootViewController;
        [rootController addChildViewController:_avpvc];
        
        _manager = [BCOVPlayerSDKManager sharedManager];
        
        NSDictionary *parsedData = args;
        
        NSDictionary *playbackControllerArgs = parsedData[@"playbackController"];
        NSNumber *autoPlay = playbackControllerArgs[@"autoPlay"];
        NSNumber *autoAdvance = playbackControllerArgs[@"autoAdvance"];
        _playbackController = ({
            id<BCOVPlaybackController> controller = [_manager createPlaybackController];
            controller.delegate = self;
            controller.autoAdvance = autoAdvance.boolValue;
            controller.autoPlay = autoPlay.boolValue;
            controller.options = @{ kBCOVAVPlayerViewControllerCompatibilityKey: @(YES) };
            controller;
        });
        
        NSDictionary *playbackServiceArgs = parsedData[@"playbackService"];
        NSString *accountId = playbackServiceArgs[@"accountId"];
        NSString *policyKey = playbackServiceArgs[@"policyKey"];
        _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:accountId policyKey:policyKey];
        
    }
    
    return self;
}

#pragma mark FlutterPlatformView

- (nonnull UIView *)view
{
    return _avpvc.view;
}

#pragma mark FlutterStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events
{
    _eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments
{
    _eventSink = nil;
    return nil;
}

#pragma mark BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    _player = session.player;
    _avpvc.player = session.player;
    
    id duration = session.video.properties[@"duration"];
    _eventSink(@{@"name": @"didAdvanceToPlaybackSession", @"duration": duration, @"isPlaying": @(self->_playbackController.isAutoPlay)});
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    if (!isinf(progress))
    {
        _eventSink(@{@"name": @"didProgressTo", @"progress":@(progress * 1000)});
    }
}

#pragma mark Private Methods

- (void)setupEventChannelWithViewIdentifier:(int64_t)viewId messenger:(NSObject<FlutterBinaryMessenger> *)messenger instance:(BCOVVideoPlayer *)instance
{
    // register for Flutter event channel
    NSString *eventChannelName = [NSString stringWithFormat:@"bcov.flutter/event_channel_%lld", viewId];
    instance->_eventChannel = [FlutterEventChannel eventChannelWithName:eventChannelName binaryMessenger:messenger codec:FlutterJSONMethodCodec.sharedInstance];
    [instance->_eventChannel setStreamHandler:instance];
}

- (void)setupMethodChannelWithViewIdentifier:(int64_t)viewId messenger:(NSObject<FlutterBinaryMessenger> *)messenger instance:(BCOVVideoPlayer *)instance
{
    // register for Flutter method channel
    NSString *methodChannelName = [NSString stringWithFormat:@"bcov.flutter/method_channel_%lld", viewId];
    instance->_methodChannel = [FlutterMethodChannel methodChannelWithName:methodChannelName binaryMessenger:messenger];
    
    __weak typeof(self) weakSelf = self;
    [instance->_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult _Nonnull result)
     {
        [weakSelf handleMethodCall:call result:result];
    }];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result
{
    if ([@"setVideo" isEqualToString:call.method])
    {
        NSString *videoId = call.arguments[@"videoId"];
        NSString *authToken = ([[call.arguments[@"authToken"] class] isKindOfClass:[NSNull class]] ?
                               call.arguments[@"authToken"] :
                               nil);
        NSDictionary *parameters = ([[call.arguments[@"parameters"] class] isKindOfClass:[NSNull class]] ?
                                    call.arguments[@"parameters"] :
                                    nil);
        
        [_playbackService findVideoWithVideoID:videoId authToken:authToken parameters:parameters completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error)
         {
            if (video)
            {
                [self->_playbackController setVideos:@[ video ]];
            }
            else
            {
                self->_eventSink(@{@"name": @"onError"});
            }
            
            result(@(YES));
        }];
    }
    else if ([@"play" isEqualToString:call.method])
    {
        [_playbackController play];
    }
    else if ([@"pause" isEqualToString:call.method])
    {
        [_playbackController pause];
    }
    else
    {
        result(FlutterMethodNotImplemented);
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    _avpvc.player = nil;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    _avpvc.player = _player;
}

@end


@implementation BCOVVideoPlayerFactory
{
    NSObject<FlutterPluginRegistrar> *_registrar;
    NSObject<FlutterBinaryMessenger> *_messenger;
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar
{
    if (self = [super init])
    {
        _registrar = registrar;
        
        _messenger = registrar.messenger;
    }
    
    return self;
}

#pragma mark FlutterPlatformViewFactory

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args
{
    return [[BCOVVideoPlayer alloc] initWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec
{
    return FlutterStandardMessageCodec.sharedInstance;
}

@end
