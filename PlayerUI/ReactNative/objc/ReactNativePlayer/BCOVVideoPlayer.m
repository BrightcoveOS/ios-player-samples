//
//  BCOVVideoPlayerView.m
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

//#import <BrightcoveIMA/BrightcoveIMA.h>
//#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

#import "BCOVVideoPlayer.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";
static NSString * const kVMAPAdTagURL = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator=";


@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate>
//@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate, IMALinkOpenerDelegate>

@property (nonatomic, strong) UIView *contentOverlayView;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@end


@implementation BCOVVideoPlayer

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectZero])
    {
        // Create the content overlay view for displaying ads (if configured)
        self.contentOverlayView = [UIView new];
        self.contentOverlayView.frame = self.bounds;
        self.contentOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

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

            id<BCOVPlaybackSessionProvider> sessionProvider = fps;

//            BOOL useIMA = YES;
//
//            if (useIMA)
//            {
//                UIViewController *presentedViewController = RCTPresentedViewController();
//
//                IMASettings *imaSettings = [IMASettings new];
//                imaSettings.language = NSLocale.currentLocale.languageCode;
//
//                IMAAdsRenderingSettings *renderSettings = [IMAAdsRenderingSettings new];
//                renderSettings.linkOpenerPresentingController = presentedViewController;
//                renderSettings.linkOpenerDelegate = self;
//
//                BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:kVMAPAdTagURL];
//
//                // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
//                // which allows us to modify the IMAAdsRequest object before it is used to load ads.
//                NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };
//
//                id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
//                                                                                                 adsRenderingSettings:renderSettings
//                                                                                                     adsRequestPolicy:adsRequestPolicy
//                                                                                                          adContainer:self.contentOverlayView
//                                                                                                       viewController:presentedViewController
//                                                                                                       companionSlots:nil
//                                                                                              upstreamSessionProvider:fps
//                                                                                                              options:imaPlaybackSessionOptions];
//
//                sessionProvider = imaSessionProvider;
//            }

            id<BCOVPlaybackController> playbackController = [sdkManager
                                                             createPlaybackControllerWithSessionProvider:sessionProvider
                                                             viewStrategy:nil];
            playbackController.delegate = self;
            playbackController.autoAdvance = YES;
            playbackController.autoPlay = YES;

            playbackController.view.frame = self.bounds;
            playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

            playbackController;
        });

        [self addSubview:self.playbackController.view];

        [self addSubview:self.contentOverlayView];

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

    if ([kBCOVPlaybackSessionLifecycleEventAdSequenceEnter isEqualToString:lifecycleEvent.eventType])
    {
        if (self.onEvent)
        {
            self.onEvent(@{ @"inAdSequence": @(YES) });
        }
    }

    if ([kBCOVPlaybackSessionLifecycleEventAdSequenceExit isEqualToString:lifecycleEvent.eventType])
    {
        if (self.onEvent)
        {
            self.onEvent(@{ @"inAdSequence": @(NO) });
        }
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


#pragma mark - BCOVIMAPlaybackSessionDelegate

//- (void)willCallIMAAdsLoaderRequestAdsWithRequest:(IMAAdsRequest *)adsRequest
//                                      forPosition:(NSTimeInterval)position
//{
//    // for demo purposes, increase the VAST ad load timeout.
//    adsRequest.vastLoadTimeout = 3000.;
//    NSLog(@"ViewController - IMAAdsRequest.vastLoadTimeout set to %.1f milliseconds.", adsRequest.vastLoadTimeout);
//}


#pragma mark - IMALinkOpenerDelegate

//- (void)linkOpenerDidOpenInAppLink:(NSObject *)linkOpener
//{
//    NSLog(@"ViewController - linkOpenerDidOpen");
//}
//
//- (void)linkOpenerDidCloseInAppLink:(NSObject *)linkOpener
//{
//    NSLog(@"ViewController - linkOpenerDidClose");
//
//    // Called when the in-app browser has closed.
//    [self.playbackController resumeAd];
//}

@end
