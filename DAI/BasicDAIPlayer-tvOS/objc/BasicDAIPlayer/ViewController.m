//
//  ViewController.m
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

#import <AppTrackingTransparency/AppTrackingTransparency.h>

#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcoveDAI/BrightcoveDAI.h>

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"1753980443013591663";

static NSString * const kViewControllerGoogleDAISourceId = @"2528370";
static NSString * const kViewControllerGoogleDAIVideoId = @"tears-of-steel";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVTVPlayerView *playerView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(tvOS 14, *))
    {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setup];
            });
        }];
    }
    else
    {
        [self setup];
    }
}


#pragma mark Setup

- (void)setup
{
    [self setupPlayerView];
    [self setupPlaybackController];
    
    [self requestContentFromPlaybackService];
}

- (void)setupPlayerView
{
    self.playerView = ({
        BCOVTVPlayerViewOptions *options = [[BCOVTVPlayerViewOptions alloc] init];
        options.presentingViewController = self;

        BCOVTVPlayerView *playerView = [[BCOVTVPlayerView alloc] initWithOptions:options];
        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.view.bounds;
        playerView;
    });

    [self.view addSubview:self.playerView];
}

- (void)setupPlaybackController
{
    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        IMASettings *imaSettings = [IMASettings new];
        imaSettings.language = NSLocale.currentLocale.localeIdentifier;

        BCOVDAIAdsRequestPolicy *adsRequestPolicy = [BCOVDAIAdsRequestPolicy videoPropertiesAdsRequestPolicy];

        id<BCOVPlaybackSessionProvider> sessionProvider = [sdkManager createDAISessionProviderWithSettings:imaSettings
                                                                                      adsRenderingSettings:nil
                                                                                          adsRequestPolicy:adsRequestPolicy
                                                                                               adContainer:self.playerView.contentOverlayView
                                                                                            viewController:self
                                                                                            companionSlots:nil
                                                                                   upstreamSessionProvider:nil];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:sessionProvider
                                                                                                   viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        playbackController;
    });

    self.playerView.playbackController = self.playbackController;
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                                policyKey:kViewControllerPlaybackServicePolicyKey];

    NSDictionary *configuration = @{
        kBCOVPlaybackServiceConfigurationKeyAssetID: kViewControllerVideoID
    };

    [playbackService findVideoWithConfiguration:configuration
                                queryParameters:nil
                                     completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (video)
        {
            BCOVVideo *updateVideo = [video update:^(id<BCOVMutableVideo> _Nonnull mutableVideo) {
                NSDictionary *adProperties = @{
                    kBCOVDAIVideoPropertiesKeySourceId: kViewControllerGoogleDAISourceId,
                    kBCOVDAIVideoPropertiesKeyVideoId: kViewControllerGoogleDAIVideoId
                };

                NSMutableDictionary *propertiesToUpdate = mutableVideo.properties.mutableCopy;
                [propertiesToUpdate addEntriesFromDictionary:adProperties];
                mutableVideo.properties = propertiesToUpdate;
            }];

            [strongSelf.playbackController setVideos:@[ updateVideo ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video");
        }
    }];
}


#pragma mark BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}


#pragma mark UI

// Preferred focus for tvOS 10+
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[ self.playerView.controlsView ?: self ];
}

@end
