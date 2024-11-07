//
//  ViewController.m
//  SLS_IMA-Player
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>
#import <BrightcoveIMA/BrightcoveIMA.h>
#import <BrightcoveSSAI/BrightcoveSSAI.h>

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"insertyouraccountidhere";
static NSString * const kPolicyKey = @"insertyourpolicykeyhere";
static NSString * const kVideoId = @"insertyourvideoidhere";
static NSString * const kAdConfigId = @"insertyouradconfigidhere";

static NSString * const kViewControllerVMAPAdTagURL = @"insertyouradtaghere";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVIMAPlaybackSessionDelegate, IMALinkOpenerDelegate>

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

        IMASettings *imaSettings = [IMASettings new];
        imaSettings.language = NSLocale.currentLocale.languageCode;

        IMAAdsRenderingSettings *renderSettings = [IMAAdsRenderingSettings new];
        renderSettings.linkOpenerPresentingController = self;
        renderSettings.linkOpenerDelegate = self;

        // BCOVIMAAdsRequestPolicy provides methods to specify
        // VAST or VMAP/Server Side Ad Rules.
        // Select the appropriate method to select your ads policy.
        BCOVIMAAdsRequestPolicy *adsRequestPolicy = adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:kViewControllerVMAPAdTagURL];

        // BCOVIMAPlaybackSessionDelegate defines
        // -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us
        // to modify the IMAAdsRequest object before it is used to load ads.
        NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
                                                                                         adsRenderingSettings:renderSettings
                                                                                             adsRequestPolicy:adsRequestPolicy
                                                                                                  adContainer:self.playerView.contentOverlayView
                                                                                               viewController:self
                                                                                               companionSlots:nil
                                                                                      upstreamSessionProvider:fps
                                                                                                      options:imaPlaybackSessionOptions];
        id<BCOVPlaybackSessionProvider> ssaiSessionProvider = [sdkManager createSSAISessionProviderWithUpstreamSessionProvider:imaSessionProvider];

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:ssaiSessionProvider
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
    NSDictionary *queryParameters = @{ BCOVPlaybackService.ParamaterKeyAdConfigId: kAdConfigId };
    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:queryParameters
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


#pragma mark - BCOVIMAPlaybackSessionDelegate

- (void)willCallIMAAdsLoaderRequestAdsWithRequest:(IMAAdsRequest *)adsRequest
                                      forPosition:(NSTimeInterval)position
{
    // for demo purposes, increase the VAST ad load timeout.
    adsRequest.vastLoadTimeout = 3000.;
    NSLog(@"ViewController - IMAAdsRequest.vastLoadTimeout set to %.1f milliseconds.", adsRequest.vastLoadTimeout);
}


#pragma mark - IMALinkOpenerDelegate

- (void)linkOpenerDidOpenInAppLink:(NSObject *)linkOpener
{
    NSLog(@"ViewController - linkOpenerDidOpenInAppLink");
}

- (void)linkOpenerDidCloseInAppLink:(NSObject *)linkOpener
{
    NSLog(@"ViewController - linkOpenerDidCloseInAppLink");
}

@end
