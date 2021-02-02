//
//  VASTOMViewController.m
//  BasicIMAPlayer
//
//  Created by Carlos Ceja on 14/01/21.
//  Copyright © 2021 BrightCove. All rights reserved.
//

#import "VASTOMViewController.h"

static NSString * const kVASTAdTagURL_openMeasurement = @"https://pubads.g.doubleclick.net/gampad/ads?iu=/124319096/external/omid_google_samples&env=vp&gdfp_req=1&output=vast&sz=640x480&description_url=http%3A%2F%2Ftest_site.com%2Fhomepage&tfcd=0&npa=0&vpmute=0&vpa=0&vad_format=linear&url=http%3A%2F%2Ftest_site.com&vpos=preroll&unviewed_position_start=1&correlator=";

@interface VASTOMViewController ()<BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@end

@implementation VASTOMViewController

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
   
    // BCOVIMAAdsRequestPolicy provides two VAST configurations:
    // `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy` and
    // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
    //
    // Using `adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy`
    // allows you to set a different VAST ad tag URL for each cue point, while using
    // `adsRequestPolicyFromCuePointPropertiesWithAdTag:adsCuePointProgressPolicy:`
    // will use the same VAST ad tag URL for each cue point.
    
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:policy];

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
    NSDictionary *preRollProperties = @{ kBCOVIMAAdTag : kVASTAdTagURL_openMeasurement };

    return [video update:^(id<BCOVMutableVideo> mutableVideo)
    {
        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kCMTimeZero properties:preRollProperties]
        ]];
        
    }];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    IMAAdDisplayContainer *displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer];
    if (displayContainer)
    {
        UIView *transparentOverlay = self.playerView.overlayView;
        IMAFriendlyObstruction *overlayObstruction = [[IMAFriendlyObstruction alloc] initWithView:transparentOverlay purpose:IMAFriendlyObstructionPurposeNotVisible detailedReason:@"Transparent overlay does not impact viewability"];
        [displayContainer registerFriendlyObstruction:overlayObstruction];

    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence
{
    IMAAdDisplayContainer *displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer];
    if (displayContainer)
    {
        [displayContainer unregisterAllFriendlyObstructions];
    }
}


@end
