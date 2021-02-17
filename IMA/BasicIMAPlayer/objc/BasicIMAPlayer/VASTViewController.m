//
//  VASTViewController.m
//  BasicIMAPlayer
//
//  Created by Jeremy Blaker on 10/23/20.
//  Copyright © 2020 BrightCove. All rights reserved.
//

#import "VASTViewController.h"

// See https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags for other sample VAST ad tag URLs
static NSString * const kVASTAdTagURL = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";

static NSString * const kVASTAdTagURL_preroll = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";
static NSString * const kVASTAdTagURL_midroll = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator=";
static NSString * const kVASTAdTagURL_postroll = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";

@interface VASTViewController ()<BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@property (nonatomic, assign) BOOL useAdTagsInCuePoints;

@end

@implementation VASTViewController

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = NSLocale.currentLocale.languageCode;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    BCOVCuePointProgressPolicy *policy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessFinalCuePoint resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead ignoringPreviouslyProcessedCuePoints:NO];
   
    // BCOVIMAAdsRequestPolicy provides two VAST configurations:
    // `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy` and
    // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
    //
    // Using `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy`
    // allows you to set a different VAST ad tag URL for each cue point, while using
    // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
    // will use the same VAST ad tag URL for each cue point.
    
    self.useAdTagsInCuePoints = YES;
    
    BCOVIMAAdsRequestPolicy *adsRequestPolicy;
    
    if (self.useAdTagsInCuePoints)
    {
        adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:policy];
    }
    else
    {
        adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyFromCuePointPropertiesWithAdTag:kVASTAdTagURL adsCuePointProgressPolicy:policy];
    }

    // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
    // which allows us to modify the IMAAdsRequest object before it is used to load ads.
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };

    self.playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings
                                                          adsRenderingSettings:renderSettings
                                                              adsRequestPolicy:adsRequestPolicy
                                                                   adContainer:self.playerView.contentOverlayView
                                                                viewController:self
                                                                companionSlots:nil
                                                                  viewStrategy:nil
                                                                       options:imaPlaybackSessionOptions];
    
    
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
    
    NSDictionary *preRollProperties = self.useAdTagsInCuePoints ? @{ kBCOVIMAAdTag : kVASTAdTagURL_preroll } : @{};
    NSDictionary *midRollProperties = self.useAdTagsInCuePoints ? @{ kBCOVIMAAdTag : kVASTAdTagURL_midroll } : @{};
    NSDictionary *postRollProperties = self.useAdTagsInCuePoints ? @{ kBCOVIMAAdTag : kVASTAdTagURL_postroll } : @{};

    return [video update:^(id<BCOVMutableVideo> mutableVideo)
    {
        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:kCMTimeZero
                                    properties:preRollProperties],
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:midpointTime
                                    properties:midRollProperties],
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:kBCOVCuePointPositionTypeAfter
                                    properties:postRollProperties]

        ]];
        
    }];
}

@end
