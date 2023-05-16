//
//  BaseViewController.m
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

#import <AppTrackingTransparency/AppTrackingTransparency.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcoveDAI/BrightcoveDAI.h>

#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

#import "BaseViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"1753980443013591663";

NSString * const kViewControllerGoogleDAISourceId = @"2528370";
NSString * const kViewControllerGoogleDAIVideoId = @"tears-of-steel";
NSString * const kViewControllerGoogleDAIAssetKey = @"sN_IYUG8STe1ZzhIIE_ksA";


@implementation BaseViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.notificationReceipt];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 14, *))
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

- (void)setup
{
    self.manager = BCOVPlayerSDKManager.sharedManager;

    BCOVPlaybackService *playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kViewControllerAccountID
                                                                                                        policyKey:kViewControllerPlaybackServicePolicyKey];
        BCOVPlaybackService *service = [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
        service;
    });

    self.playbackService = playbackService;

    BCOVPUIPlayerView *playerView = ({
        BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
        options.presentingViewController = self;
        options.automaticControlTypeSelection = YES;

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil
                                                                                      options:options
                                                                                 controlsView:nil];
        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];
        playerView;
    });

    self.playerView = playerView;

    [self setupPlaybackController];

    [self resumeAdAfterForeground];

    [self requestContentFromPlaybackService];
}

- (void)setupPlaybackController
{
    // NO-OP
}

- (BCOVVideo *)updateVideo:(BCOVVideo *)video
{
    return video;
}

- (void)resumeAdAfterForeground
{
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.

    __weak typeof(self) weakSelf = self;

    self.notificationReceipt = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                                                 object:nil
                                                                                  queue:nil
                                                                             usingBlock:^(NSNotification *note) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.adIsPlaying)
        {
            [strongSelf.playbackController resumeAd];
        }

    }];
}

- (void)requestContentFromPlaybackService
{
    NSDictionary *configuration = @{
        kBCOVPlaybackServiceConfigurationKeyAssetID: kViewControllerVideoID
    };

    __weak typeof(self) weakSelf = self;

    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:nil
                                          completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (video)
        {
            BCOVVideo *updatedVideo = [strongSelf updateVideo:video];

            [strongSelf.playbackController setVideos:@[ updatedVideo ]];
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
    NSLog(@"ViewController - Advanced to new session.");

    // Enable route detection for AirPlay
    // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
    self.playerView.controlsView.routeDetector.routeDetectionEnabled = YES;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined BCOVDAIComponent.h.
    NSString *type = lifecycleEvent.eventType;

    if ([type isEqualToString:kBCOVDAILifecycleEventAdsLoaderLoaded])
    {
        NSLog(@"ViewController - Ads loaded.");
    }
    else if ([type isEqualToString:kBCOVDAILifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];
        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                NSLog(@"ViewController - Ad Started.");
                self.adIsPlaying = YES;
                break;
            case kIMAAdEvent_COMPLETE:
                NSLog(@"ViewController - Ad Completed.");
                self.adIsPlaying = NO;
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController - All ads completed.");
                break;
            default:
                break;
        }
    }
    else if ([type isEqualToString:kBCOVPlaybackSessionLifecycleEventEnd])
    {
        // Disable route detection for AirPlay
        // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
        self.playerView.controlsView.routeDetector.routeDetectionEnabled = NO;
    }
}


#pragma mark IMALinkOpenerDelegate

- (void)linkOpenerWillOpenInAppLink:(NSObject *)linkOpener
{
    NSLog(@"IMALinkOpenerDelegate: In-app browser will open");
}

- (void)linkOpenerDidOpenInAppLink:(NSObject *)linkOpener
{
    NSLog(@"IMALinkOpenerDelegate: In-app browser did open");
}

- (void)linkOpenerWillCloseInAppLink:(NSObject *)linkOpener
{
    NSLog(@"IMALinkOpenerDelegate: In-app browser will close");
}

- (void)linkOpenerDidCloseInAppLink:(NSObject *)linkOpener
{
    NSLog(@"IMALinkOpenerDelegate: In-app browser did close");
    
    if (self.adIsPlaying)
    {
        [self.playbackController resumeAd];
    }
}

@end
