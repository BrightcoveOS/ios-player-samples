//
//  BCOVVideoPlayer.m
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

//#import <BrightcoveIMA/BrightcoveIMA.h>
//#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

#import "AppDelegate.h"
#import "BCOVThumbnailManager.h"

#import "BCOVVideoPlayer.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";
static NSString * const kVMAPAdTagURL = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator=";


@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate>
//@interface BCOVVideoPlayer () <BCOVPlaybackControllerDelegate, IMALinkOpenerDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *contentOverlayView;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVThumbnailManager *thumbnailManager;

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, strong) FlutterEventSink eventSink;

@end


@implementation BCOVVideoPlayer

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
{
    if (self = [super init])
    {
        // Create the container that will contain the player and content overlay views
        self.containerView = [UIView new];

        // Create the content overlay view for displaying ads (if configured)
        self.contentOverlayView = ({
            UIView *contentOverlayView = [UIView new];
            contentOverlayView.frame = self.containerView.bounds;
            contentOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

            contentOverlayView;
        });

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
            //                FlutterViewController *flutterViewController = ((AppDelegate *)UIApplication.sharedApplication.delegate).flutterViewController;
            //
            //                IMASettings *imaSettings = [IMASettings new];
            //                imaSettings.language = NSLocale.currentLocale.languageCode;
            //
            //                IMAAdsRenderingSettings *renderSettings = [IMAAdsRenderingSettings new];
            //                renderSettings.linkOpenerPresentingController = flutterViewController;
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
            //                                                                                                       viewController:flutterViewController
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

            playbackController.view.frame = self.containerView.frame;
            playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

            playbackController;
        });

        [self.containerView addSubview:self.playbackController.view];

        [self.containerView addSubview:self.contentOverlayView];

        // register for Flutter method channel
        self.methodChannel = ({
            FlutterEngine *flutterEngine = ((AppDelegate *)UIApplication.sharedApplication.delegate).flutterEngine;
            FlutterMethodChannel *methodChannel = [FlutterMethodChannel
                                                   methodChannelWithName:@"bcov.flutter/method_channel"
                                                   binaryMessenger:flutterEngine.binaryMessenger];
            __weak typeof(self) weakSelf = self;
            [methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call,
                                                  FlutterResult _Nonnull result) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf handleMethodCall:call
                                      result:result];
            }];
            methodChannel;
        });

        // register for Flutter event channel
        self.eventChannel = ({
            FlutterEngine *flutterEngine = ((AppDelegate *)UIApplication.sharedApplication.delegate).flutterEngine;
            FlutterEventChannel *eventChannel = [FlutterEventChannel
                                                 eventChannelWithName:@"bcov.flutter/event_channel"
                                                 binaryMessenger:flutterEngine.binaryMessenger
                                                 codec:FlutterJSONMethodCodec.sharedInstance];
            [eventChannel setStreamHandler:self];
            eventChannel;
        });

        [self requestContentFromPlaybackService];
    }

    return self;
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
                    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
                    [rootViewController presentViewController:alert animated:YES completion:nil];
                });

                return;
            }
#endif

            if (strongSelf.playbackController.thumbnailSeekingEnabled)
            {
                [strongSelf handleThumbnailsForVideo:video];
            }

            [strongSelf.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }

    }];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result
{
    if ([@"playPause" isEqualToString:call.method])
    {
        NSNumber *isPlaying = call.arguments;
        if (isPlaying.boolValue)
        {
            [self.playbackController pause];
        }
        else
        {
            [self.playbackController play];
        }

        result(nil);
    }
    else if ([@"seek" isEqualToString:call.method])
    {
        NSNumber *seconds = call.arguments;
        CMTime seekTo = CMTimeMakeWithSeconds(seconds.intValue, 600);
        [self.playbackController seekToTime:seekTo
                            toleranceBefore:kCMTimeZero
                             toleranceAfter:kCMTimeZero
                          completionHandler:nil];

        result(nil);
    }
    else if ([@"thumbnailAtTime" isEqualToString:call.method])
    {
        NSNumber *seconds = call.arguments;
        CMTime thumbnailTime = CMTimeMakeWithSeconds(seconds.intValue, 600);
        NSURL *url = [self.thumbnailManager thumbnailAtTime:thumbnailTime];
        if (url)
        {
            result(url.absoluteString);
        }
    }
    else
    {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleThumbnailsForVideo:(BCOVVideo *)video
{
    NSArray *textTracks = video.properties[BCOVVideo.PropertyKeyTextTracks];

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"src" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.label MATCHES %@ AND (SELF.src BEGINSWITH %@ OR SELF.src BEGINSWITH %@)", @"thumbnails", @"https://", @"http://"];
    NSArray *filtered = [[textTracks filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sort]];

    if (filtered.count > 1)
    {
        NSDictionary *textTrack = filtered.firstObject;
        NSString *trackSrc = textTrack[@"src"];
        NSURL *thumbnailURL = [NSURL URLWithString:trackSrc];

        self.thumbnailManager = [[BCOVThumbnailManager alloc] initWithURL:thumbnailURL];
    }
}

- (NSURL *)thumbnailAtTime:(NSNumber *)value
{
    if (self.thumbnailManager)
    {
        NSURL *thumbnailURL = [self.thumbnailManager thumbnailAtTime:value.CMTimeValue];
        return thumbnailURL;
    }

    return nil;
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");

    NSNumber *duration = session.video.properties[BCOVVideo.PropertyKeyDuration];
    self.eventSink(@{ @"name": @"didAdvanceToPlaybackSession",
                      @"duration": duration,
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

    if ([kBCOVPlaybackSessionLifecycleEventEnd isEqualToString:lifecycleEvent.eventType])
    {
        self.eventSink(@{ @"name": @"eventEnd" });
    }

    if ([kBCOVPlaybackSessionLifecycleEventAdSequenceEnter isEqualToString:lifecycleEvent.eventType])
    {
        self.eventSink(@{ @"name": @"eventAdSequenceEnter" });
    }

    if ([kBCOVPlaybackSessionLifecycleEventAdSequenceExit isEqualToString:lifecycleEvent.eventType])
    {
        self.eventSink(@{ @"name": @"eventAdSequenceExit" });
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
             didProgressTo:(NSTimeInterval)progress
{
    if (!isinf(progress))
    {
        self.eventSink(@{ @"name": @"didProgressTo",
                          @"progress": @(progress) });
    }
}


#pragma mark - FlutterPlatformView

- (nonnull UIView *)view
{
    return self.containerView;
}


#pragma mark - FlutterStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments
                              eventSink:(FlutterEventSink)events
{
    self.eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments
{
    self.eventSink = nil;
    return nil;
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
