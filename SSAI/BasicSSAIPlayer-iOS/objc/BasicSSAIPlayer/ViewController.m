//
//  ViewController.m
//  BasicSSAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <BrightcoveSSAI/BrightcoveSSAI.h>
// #import <OMSDK_Brightcove/OMSDK.h>

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"5702141808001";
static NSString * const kAdConfigId = @"0e0bbcd1-bba0-45bf-a986-1288e5f9fc85";
static NSString * const kVMAPURL = @"https://sdks.support.brightcove.com/assets/ads/ssai/sample-vmap.xml";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIView *companionSlotContainerView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, assign) BOOL useVMAPURL;

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

    [self setup];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(requestTrackingAuthorization)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setup
{
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

        // To take the advantage of using IAB Open Measurement,
        // the SSAI Plugin for iOS provides a new signature:
        // [BCOVPlayerSDKManager createSSAISessionProviderWithUpstreamSessionProvider:omidPartner:]
        //
        // id<BCOVPlaybackSessionProvider> ssaiSessionProvider = [sdkManager createSSAISessionProviderWithupstreamSessionProvider:fps
        //                                                                                                            omidPartner:@"yourOmidPartner"];
        //
        // The `omidPartner` string identifies the integration.
        // The value can not be empty or nil, if partner is not available, use "unknown".
        // The IAB Tech Lab will assign a unique partner name to you at the time of integration,
        // so this is the value you should use here.

        id<BCOVPlaybackSessionProvider> ssaiSessionProvider = [sdkManager createSSAISessionProviderWithUpstreamSessionProvider:fps];

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:ssaiSessionProvider
                                                         viewStrategy:nil];

        // Create a companion slot.
        BCOVSSAICompanionSlot *companionSlot = [[BCOVSSAICompanionSlot alloc] initWithView:self.companionSlotContainerView
                                                                                     width:300
                                                                                    height:250];

        // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
        BCOVSSAIAdComponentDisplayContainer *adComponentDisplayContainer = [[BCOVSSAIAdComponentDisplayContainer alloc] initWithCompanionSlots:@[ companionSlot ]];


        // In order for the ad display container to receive ad information, we add it as a session consumer.
        [playbackController addSessionConsumer:adComponentDisplayContainer];

        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });
}

- (void)requestTrackingAuthorization
{
    if (@available(iOS 14.5, *))
    {
        __weak typeof(self) weakSelf = self;

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

            __strong typeof(weakSelf) strongSelf = weakSelf;

            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed.
                // Start loading ads here.
                if (strongSelf.useVMAPURL)
                {
                    NSURL *url = [NSURL URLWithString:kVMAPURL];
                    BCOVVideo *video = [BCOVVideo videoWithURL:url];

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
                    [strongSelf requestContentFromPlaybackService];
                }
            });

        }];
    }
    else
    {
        if (self.useVMAPURL)
        {
            NSURL *url = [NSURL URLWithString:kVMAPURL];
            BCOVVideo *video = [BCOVVideo videoWithURL:url];
            [self.playbackController setVideos:@[ video ]];
        }
        else
        {
            [self requestContentFromPlaybackService];
        }
    }

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId };
    NSDictionary *queryParamaters = @{ kBCOVPlaybackServiceParamaterKeyAdConfigId: kAdConfigId };

    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:queryParamaters
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


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

@end
