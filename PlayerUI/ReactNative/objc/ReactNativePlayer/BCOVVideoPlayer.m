//
//  BCOVVideoPlayerView.m
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <React/RCTBridgeModule.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVVideoPlayer.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";


@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) AVPlayerViewController *avpvc;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@end


@implementation BCOVVideoPlayer

- (instancetype)init
{
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds])
    {
        self.playbackService = ({
            BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                          initWithAccountId:kAccountId
                                                          policyKey:kPolicyKey];

            [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
        });

        self.playbackController = ({
            BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

            BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                              applicationId:nil];

            id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                          upstreamSessionProvider:nil];

            id<BCOVPlaybackController> playbackController = [sdkManager
                                                             createPlaybackControllerWithSessionProvider:fps
                                                             viewStrategy:nil];
            playbackController.delegate = self;
            playbackController.autoAdvance = YES;
            playbackController.autoPlay = YES;

            playbackController;
        });

        self.avpvc = ({
            AVPlayerViewController *avpvc = [AVPlayerViewController new];
            avpvc.showsPlaybackControls = NO;
            avpvc;
        });

        [self addSubview:self.avpvc.view];

        [self requestContentFromPlaybackService];
    }
    
    return self;
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId };
    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:nil
                                          completion:^(BCOVVideo *video,
                                                       NSDictionary *jsonResponse,
                                                       NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (video)
        {
#if TARGET_OS_SIMULATOR
            if (video.usesFairPlay)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FairPlay Warning"
                                                                               message:@"FairPlay only works on actual iOS or tvOS devices.\n\nYou will not be able to view any FairPlay content in the iOS or tvOS simulator."
                                                                        preferredStyle:UIAlertControllerStyleAlert];

                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
                    [rootViewController presentViewController:alert animated:YES completion:nil];
                });

                return;
            }
#endif

            [strongSelf.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }

    }];
}

- (void)playPause:(BOOL)isPlaying
{
    if (isPlaying)
    {
        [self.playbackController pause];
    }
    else
    {
        [self.playbackController play];
    }
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");

    self.avpvc.player = session.player;

    NSNumber *duration = session.video.properties[kBCOVVideoPropertyKeyDuration];
    self.onReady(@{ @"duration": duration,
                    @"isAutoPlay": @(controller.isAutoPlay) });
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
  didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[@"error"];
        // Report any errors that may have occurred with playback.
        NSLog(@"ViewController - Playback error: %@", error.localizedDescription);
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
             didProgressTo:(NSTimeInterval)progress
{
    if (self.onProgress && !isinf(progress))
    {
        self.onProgress(@{ @"progress": @(progress) });
    }
}

@end
