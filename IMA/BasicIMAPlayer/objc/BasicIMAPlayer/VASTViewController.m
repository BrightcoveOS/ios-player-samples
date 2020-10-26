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

@interface VASTViewController ()<BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@end

@implementation VASTViewController

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    BCOVCuePointProgressPolicy *policy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessFinalCuePoint resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead ignoringPreviouslyProcessedCuePoints:NO];
   
    // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:policy];
   
    self.playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings
                                                      adsRenderingSettings:renderSettings
                                                          adsRequestPolicy:adsRequestPolicy
                                                               adContainer:self.playerView.contentOverlayView
                                                            viewController:self
                                                            companionSlots:nil
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

    return [video update:^(id<BCOVMutableVideo> mutableVideo)
    {
        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:kCMTimeZero
                                    properties:@{ kBCOVIMAAdTag : kVASTAdTagURL }],
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:midpointTime
                                    properties:@{ kBCOVIMAAdTag : kVASTAdTagURL }],
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd
                                      position:kBCOVCuePointPositionTypeAfter
                                    properties:@{ kBCOVIMAAdTag : kVASTAdTagURL }]

        ]];
        
    }];
}

@end
