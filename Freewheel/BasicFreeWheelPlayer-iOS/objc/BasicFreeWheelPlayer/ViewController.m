//
//  ViewController.m
//  BasicFreeWheelPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdManager/AdManager.h>
#import <BrightcoveFW/BrightcoveFW.h>

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";

static NSInteger const kNetworkId = 42015;
static NSString * const kServerURL = @"http://demo.v.fwmrm.net";
static NSString * const kPlayerProfile = @"42015:ios_allinone_profile";
static NSString * const kSiteSectionId = @"ios_allinone_demo_site_section";
static NSString * const kVideoAssetId = @"ios_allinone_demo_video";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) id<FWAdManager> adManager;
@property (nonatomic, weak) BCOVFWContext *bcovAdContext;

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

    self.adManager = newAdManager();
    [self.adManager setNetworkId: kNetworkId];

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

        BCOVFWSessionProviderOptions *options = [BCOVFWSessionProviderOptions new];
        options.cuePointProgressPolicy = [BCOVCuePointProgressPolicy
                                          progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessFinalCuePoint
                                          resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead
                                          ignoringPreviouslyProcessedCuePoints:YES];

        BCOVFWSessionProviderAdContextPolicy adContextPolicy = [self adContextPolicy];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        id<BCOVPlaybackSessionProvider> fwSessionProvider = [sdkManager
                                                             createFWSessionProviderWithAdContextPolicy:adContextPolicy
                                                             upstreamSessionProvider:fps
                                                             options:options];

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:fwSessionProvider
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

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BCOVFWSessionProviderAdContextPolicy)adContextPolicy
{
    __weak typeof(self) weakSelf = self;

    return [^ BCOVFWContext * (BCOVVideo *video,
                               BCOVSource *source,
                               NSTimeInterval duration) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        // This block will get called before every session is delivered. The source,
        // video, and duration are provided in case you need to use them to
        // customize the these settings.
        // The values below are specific to this sample app, and should be changed
        // appropriately. For information on what values need to be provided,
        // please refer to your FreeWheel documentation or contact your FreeWheel
        // account executive. Basic information is provided below.
        id<FWContext> adContext = [strongSelf.adManager newContext];

        // This is the view where the ads will be rendered.
        [adContext setVideoDisplayBase: strongSelf.playerView.contentOverlayView];

        FWRequestConfiguration *adRequestConfig = [[FWRequestConfiguration alloc]
                                                   initWithServerURL:kServerURL
                                                   playerProfile:kPlayerProfile
                                                   playerDimensions:self.videoContainerView.frame.size];

        adRequestConfig.siteSectionConfiguration = [[FWSiteSectionConfiguration alloc]
                                                    initWithSiteSectionId:kSiteSectionId
                                                    idType: FWIdTypeCustom];

        adRequestConfig.videoAssetConfiguration = [[FWVideoAssetConfiguration alloc]
                                                   initWithVideoAssetId:kVideoAssetId
                                                   idType:FWIdTypeCustom
                                                   duration:duration
                                                   durationType:FWVideoAssetDurationTypeExact
                                                   autoPlayType:FWVideoAssetAutoPlayTypeAttended];

        [adRequestConfig addSlotConfiguration:[[FWTemporalSlotConfiguration alloc]
                                               initWithCustomId:@"preroll"
                                               adUnit:FWAdUnitPreroll
                                               timePosition:0.0]];

        [adRequestConfig addSlotConfiguration:[[FWTemporalSlotConfiguration alloc]
                                               initWithCustomId:@"midroll60"
                                               adUnit:FWAdUnitMidroll
                                               timePosition:60.0]];

        [adRequestConfig addSlotConfiguration:[[FWTemporalSlotConfiguration alloc]
                                               initWithCustomId:@"midroll120"
                                               adUnit:FWAdUnitMidroll
                                               timePosition:120.0]];

        [adRequestConfig addSlotConfiguration:[[FWTemporalSlotConfiguration alloc]
                                               initWithCustomId:@"postroll"
                                               adUnit:FWAdUnitPostroll
                                               timePosition:0.0]];

        BCOVFWContext *bcovAdContext = [[BCOVFWContext alloc]
                                        initWithAdContext:adContext
                                        requestConfiguration:adRequestConfig];

        // We save the adContext to the class so that
        // we can access outside the block.
        strongSelf.bcovAdContext = bcovAdContext;

        return bcovAdContext;

    } copy];
}

- (void)requestTrackingAuthorization
{
    if (@available(iOS 14.5, *))
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
