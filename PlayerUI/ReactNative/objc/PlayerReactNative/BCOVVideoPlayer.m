//
//  BCOVVideoPlayerView.m
//  PlayerReactNative
//
//  Created by Carlos Ceja.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import <React/RCTBridgeModule.h>

#import "BCOVVideoPlayer.h"


@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate>

@end


@implementation BCOVVideoPlayer
{
    RCTEventDispatcher *_eventDispatcher;
    
    AVPlayer *_player;
    AVPlayerViewController *_avpvc;
    
    BCOVPlayerSDKManager *_manager;
    BCOVPlaybackService *_playbackService;
    id<BCOVPlaybackController> _playbackController;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds])
    {
        _eventDispatcher = eventDispatcher;
        
        _player = [[AVPlayer alloc] init];
        
        _avpvc = ({
            AVPlayerViewController *avpvc = [[AVPlayerViewController alloc] init];
            avpvc.player = _player;
            avpvc.showsPlaybackControls = NO;
            avpvc;
        });
        
        _manager = [BCOVPlayerSDKManager sharedManager];
        
        [self addSubview:_avpvc.view];
    }
    
    return self;
}

- (void)setOptions:(NSDictionary *)options
{
    _options = options;
    
    NSDictionary *playbackControllerArgs = _options[@"playbackController"];
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
    
    NSDictionary *playbackServiceArgs = _options[@"playbackService"];
    NSString *accountId = playbackServiceArgs[@"accountId"];
    NSString *policyKey = playbackServiceArgs[@"policyKey"];
    _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:accountId policyKey:policyKey];
    
    
    NSString *videoId = playbackServiceArgs[@"videoId"];
    NSString *authToken = ([[playbackServiceArgs[@"authToken"] class] isKindOfClass:[NSNull class]] ?
                           playbackServiceArgs[@"authToken"] :
                           nil);
    NSDictionary *parameters = ([[playbackServiceArgs[@"parameters"] class] isKindOfClass:[NSNull class]] ?
                                playbackServiceArgs[@"parameters"] :
                                nil);
    
    [_playbackService findVideoWithVideoID:videoId authToken:authToken parameters:parameters completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error)
     {
        if (video)
        {
            [self->_playbackController setVideos:@[ video ]];
        }
        
    }];
}

- (void)playPause:(BOOL)isPlaying
{
    if (isPlaying)
    {
        [_player pause];
    }
    else
    {
        [_player play];
    }
}

#pragma mark BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    _player = session.player;
    _avpvc.player = session.player;
    
    if (self.onReady)
    {
        id duration = session.video.properties[@"duration"];
        self.onReady(@{@"duration": duration});
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    if (self.onProgress && !isinf(progress))
    {
        self.onProgress(@{@"progress": @(progress)});
    }
}

@end
