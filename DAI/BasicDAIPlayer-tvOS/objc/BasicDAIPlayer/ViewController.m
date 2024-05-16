//
//  ViewController.m
//  BasicDAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>
#import <BrightcoveDAI/BrightcoveDAI.h>

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"1753980443013591663";

static NSString * const kGoogleDAISourceId = @"2528370";
static NSString * const kGoogleDAIVideoId = @"tears-of-steel";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVTVPlayerView *playerView;

@end


@implementation ViewController

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[ self.playerView.controlsView ?: self ];
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
        BCOVTVPlayerViewOptions *options = [[BCOVTVPlayerViewOptions alloc] init];
        options.presentingViewController = self;

        BCOVTVPlayerView *playerView = [[BCOVTVPlayerView alloc] initWithOptions:options];
        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.view.bounds;

        [self.view addSubview:playerView];

        playerView;
    });

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        IMASettings *imaSettings = [IMASettings new];
        imaSettings.language = NSLocale.currentLocale.localeIdentifier;

        BCOVDAIAdsRequestPolicy *adsRequestPolicy = [BCOVDAIAdsRequestPolicy videoPropertiesAdsRequestPolicy];

        id<BCOVPlaybackSessionProvider> sessionProvider = [sdkManager createDAISessionProviderWithSettings:imaSettings
                                                                                      adsRenderingSettings:nil
                                                                                          adsRequestPolicy:adsRequestPolicy
                                                                                               adContainer:self.playerView.contentOverlayView
                                                                                            viewController:self
                                                                                            companionSlots:nil
                                                                                   upstreamSessionProvider:fps];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:sessionProvider
                                                                                                   viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(requestTrackingAuthorization)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)requestTrackingAuthorization
{
    if (@available(tvOS 14.5, *))
    {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            switch (status)
            {
                case ATTrackingManagerAuthorizationStatusAuthorized:
                    NSLog(@"Authorized Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusDenied:
                    NSLog(@"Denied Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusNotDetermined:
                    NSLog(@"Not Determined Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusRestricted:
                    NSLog(@"Restricted Tracking Permission");
                    break;
            }

            NSLog(@"IDFA: %@", ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString);

            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed.
                // Start loading ads here.
                [self requestContentFromPlaybackService];
            });

        }];
    }
    else
    {
        [self requestContentFromPlaybackService];
    }

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
}

- (void)requestContentFromPlaybackService
{
    NSDictionary *configuration = @{
        kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId
    };

    __weak typeof(self) weakSelf = self;

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

            BCOVVideo *updateVideo = [video update:^(id<BCOVMutableVideo> _Nonnull mutableVideo) {
                NSDictionary *adProperties = @{
                    kBCOVDAIVideoPropertiesKeySourceId: kGoogleDAISourceId,
                    kBCOVDAIVideoPropertiesKeyVideoId: kGoogleDAIVideoId
                };

                NSMutableDictionary *propertiesToUpdate = mutableVideo.properties.mutableCopy;
                [propertiesToUpdate addEntriesFromDictionary:adProperties];
                mutableVideo.properties = propertiesToUpdate;
            }];

            [strongSelf.playbackController setVideos:@[ updateVideo ]];
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


#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
        didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController - Entering ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
         didExitAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController - Exiting ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
                didEnterAd:(BCOVAd *)ad
{
    NSLog(@"ViewController - Entering ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
                 didExitAd:(BCOVAd *)ad
{
    NSLog(@"ViewController - Exiting ad");
}

@end
