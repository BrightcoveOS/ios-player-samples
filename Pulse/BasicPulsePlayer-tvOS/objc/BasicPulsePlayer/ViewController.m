//
//  ViewController.m
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <Pulse_tvOS/Pulse.h>
#import <BrightcovePulse/BrightcovePulse.h>

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";

// Replace with your own Pulse Host info
static NSString * const kPulseHost = @"https://bc-test.videoplaza.tv";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVTVPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@end


@implementation ViewController

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[ self.playerView.controlsView ?: self ];
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

- (void)setup
{
    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playerView = ({
        BCOVTVPlayerViewOptions *options = [BCOVTVPlayerViewOptions new];
        options.presentingViewController = self;
        options.automaticControlTypeSelection = YES;

        BCOVTVPlayerView *playerView = [[BCOVTVPlayerView alloc] initWithOptions:options];
        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.view.bounds;
        [self.view addSubview:playerView];

        playerView;
    });

    self.playbackController = ({
        /**
         *  Initialize the Brightcove Pulse Plugin.
         *  Host:
         *      The host is derived from the "sub-domain” found in the Pulse UI and is formulated
         *      like this: `https://[sub-domain].videoplaza.tv`
         *  Device Container (kBCOVPulseOptionPulseDeviceContainerKey):
         *      The device container in Pulse is used for targeting and reporting purposes.
         *      This device container attribute is only used if you want to override the Pulse
         *      device detection algorithm on the Pulse ad server. This should only be set if normal
         *      device detection does not work and only after consulting our personnel.
         *      An incorrect device container value can result in no ads being served
         *      or incorrect ad delivery and reports.
         *  Persistent Id (kBCOVPulseOptionPulsePersistentIdKey):
         *      The persistent identifier is used to identify the end user and is the
         *      basis for frequency capping, uniqueness, DMP targeting information and
         *      more. Use Apple's advertising identifier (IDFA), or your own unique
         *      user identifier here.
         *
         *  Refer to:
         *  https://docs.invidi.com/r/INVIDI-Pulse-Documentation/Pulse-SDKs-parameter-reference
         */

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
        OOContentMetadata *contentMetadata = [OOContentMetadata new];
        contentMetadata.tags = @[ @"standard-linears" ];

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
        OORequestSettings *requestSettings = [OORequestSettings new];
        requestSettings.linearPlaybackPositions = @[ @(45), @(90), @(135)];

        NSString *persistentId = ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;

        NSDictionary *pulsePlaybackSessionOptions = @{ kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
                                                       kBCOVPulseOptionPulsePersistentIdKey: persistentId };

        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        id<BCOVPlaybackSessionProvider> pulseSessionProvider = [sdkManager createPulseSessionProviderWithPulseHost:kPulseHost
                                                                                                   contentMetadata:contentMetadata
                                                                                                   requestSettings:requestSettings
                                                                                                       adContainer:self.playerView.contentOverlayView
                                                                                                    companionSlots:nil
                                                                                           upstreamSessionProvider:fps
                                                                                                           options:pulsePlaybackSessionOptions];

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:pulseSessionProvider
                                                         viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });
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

@end
