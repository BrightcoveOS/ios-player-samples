//
//  VASTViewController.m
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>
#import <BrightcoveIMA/BrightcoveIMA.h>

#import "VASTViewController.h"


// See https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags for other sample VAST ad tag URLs
static NSString * const kVASTAdTagURL = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";


@interface VASTViewController ()

@property (nonatomic, assign) BOOL useAdTagsInCuePoints;

@end


@implementation VASTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.useAdTagsInCuePoints = YES;
}

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

    IMASettings *imaSettings = [IMASettings new];
    imaSettings.language = NSLocale.currentLocale.languageCode;

    IMAAdsRenderingSettings *renderSettings = [IMAAdsRenderingSettings new];
    renderSettings.linkOpenerPresentingController = self;
    renderSettings.linkOpenerDelegate = self;

    BCOVCuePointProgressPolicy *policy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessFinalCuePoint
                                                                                  resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead
                                                                  ignoringPreviouslyProcessedCuePoints:NO];

    // BCOVIMAAdsRequestPolicy provides two VAST configurations:
    // `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy` and
    // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
    //
    // Using `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy`
    // allows you to set a different VAST ad tag URL for each cue point, while using
    // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
    // will use the same VAST ad tag URL for each cue point.

    BCOVIMAAdsRequestPolicy *adsRequestPolicy;

    if (self.useAdTagsInCuePoints)
    {
        adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:policy];
    }
    else
    {
        adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyFromCuePointPropertiesWithAdTag:kVASTAdTagURL
                                                                          adsCuePointProgressPolicy:policy];
    }

    // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
    // which allows us to modify the IMAAdsRequest object before it is used to load ads.
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };

    id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
                                                                                     adsRenderingSettings:renderSettings
                                                                                         adsRequestPolicy:adsRequestPolicy
                                                                                              adContainer:self.playerView.contentOverlayView
                                                                                           viewController:self
                                                                                           companionSlots:self.companionAdSlots
                                                                                  upstreamSessionProvider:self.fps
                                                                                                  options:imaPlaybackSessionOptions];

    self.playbackController = [sdkManager createPlaybackControllerWithSessionProvider:imaSessionProvider
                                                                         viewStrategy:nil];

    self.playbackController.delegate = self;
    self.playbackController.autoAdvance = YES;
    self.playbackController.autoPlay = YES;

    self.playerView.playbackController = self.playbackController;
}

- (BCOVVideo *)updateVideo:(BCOVVideo *)video
{
    // Determine mid-point of video so we can insert a cue point there
    CGFloat durationMiliSeconds = ((NSNumber *)video.properties[@"duration"]).doubleValue;
    CGFloat midpointSeconds = (durationMiliSeconds / 2) / 1000;
    CMTime midpointTime = CMTimeMakeWithSeconds(midpointSeconds, 1);

    NSDictionary *properties = self.useAdTagsInCuePoints ? @{ kBCOVIMAAdTag: kVASTAdTagURL } : @{};

    return [video update:^(id<BCOVMutableVideo> mutableVideo)
            {
        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:kCMTimeZero
                                    properties:properties],
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:midpointTime
                                    properties:properties],
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:kBCOVCuePointPositionTypeAfter
                                    properties:properties]
        ]];
    }];
}

@end
