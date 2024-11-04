//
//  ViewController.m
//  BasicOmniturePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;
#import <BrightcoveAMC/BrightcoveAMC.h>

#import "ADBMobile.h"
#import "ADBMediaHeartbeat.h"
#import "ADBMediaHeartbeatConfig.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVAMCSessionConsumerHeartbeatDelegate, BCOVAMCSessionConsumerMediaDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        options.presentingViewController = self;
        options.automaticControlTypeSelection = YES;

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:nil];

        playerView.delegate = self;

        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];

        playerView;
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

        self.playerView.playbackController = playbackController;

        // Use Adobe Video Media Heartbeat v2.0 analytics
        [playbackController addSessionConsumer: [self videoHeartbeatSessionConsumer]];
        // OR use Adobe media analytics
        // [playbackController addSessionConsumer: [self mediaAnalyticsSessionConsumer]];

        playbackController;
    });

    [self requestContentFromPlaybackService];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BCOVAMCSessionConsumer *)videoHeartbeatSessionConsumer
{
    BCOVAMCVideoHeartbeatConfigurationPolicy videoHeartbeatConfigurationPolicy =
    ^ADBMediaHeartbeatConfig *(id<BCOVPlaybackSession> session) {

        ADBMediaHeartbeatConfig *configData = [ADBMediaHeartbeatConfig new];

        configData.trackingServer = @"ovppartners.hb.omtrdc.net";
        configData.channel = @"test-channel";
        configData.appVersion = @"1.0.0";
        configData.ovp = @"Brightcove";
        configData.playerName = @"BasicOmniturePlayer";
        configData.ssl = NO;

        // NOTE: remove this in production code.
        configData.debugLogging = YES;

        return configData;
    };

    BCOVAMCAnalyticsPolicy *heartbeatPolicy = [[BCOVAMCAnalyticsPolicy alloc] initWithHeartbeatConfigurationPolicy:videoHeartbeatConfigurationPolicy];

    return [BCOVAMCSessionConsumer heartbeatAnalyticsConsumerWithPolicy:heartbeatPolicy
                                                               delegate:self];
}

- (BCOVAMCSessionConsumer *)mediaAnalyticsSessionConsumer
{
    BCOVAMCMediaSettingPolicy mediaSettingPolicy =
    ^ADBMediaSettings *(id<BCOVPlaybackSession> session) {
        ADBMediaSettings *settings = [ADBMobile mediaCreateSettingsWithName:@"BCOVOmniturePlayerMediaSettings"
                                      // You can set video length to 0. Omniture plugin will update it later for you.
                                                                     length:0
                                                                 playerName:@"BasicOmniturePlayer"
                                                                   playerID:@"BasicOmniturePlayer"];
        // Adobe media analytics setting customization
        // settings.milestones = @"25,50,75";

        return settings;
    };

    BCOVAMCAnalyticsPolicy *mediaPolicy = [[BCOVAMCAnalyticsPolicy alloc]
                                           initWithMediaSettingsPolicy:mediaSettingPolicy];

    return [BCOVAMCSessionConsumer mediaAnalyticsConsumerWithPolicy:mediaPolicy
                                                           delegate:self];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId };
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
                    [strongSelf presentViewController:alert animated:YES completion:nil];
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


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");
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


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}


#pragma mark - BCOVAMCSessionConsumerHeartbeatDelegate

- (void)heartbeatVideoUnloadedOnSession:(id<BCOVPlaybackSession>)session;
{
    NSLog(@"ViewController - heartbeatVideoUnloadedOnSession:");
}


#pragma mark - BCOVAMCSessionConsumerMediaDelegate

- (void)mediaOnSession:(id<BCOVPlaybackSession>)session
            mediaState:(ADBMediaState *)mediaState;
{
    NSLog(@"ViewController - mediaEvent = %@", mediaState.mediaEvent);

    if([mediaState.mediaEvent isEqualToString:@"MILESTONE"])
    {
        NSLog(@"ViewController - milestone = %lu", (unsigned long)mediaState.milestone);
    }
}

@end
