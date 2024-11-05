//
//  VASTOMViewController.m
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>
#import <BrightcoveIMA/BrightcoveIMA.h>

#import "VASTOMViewController.h"


// See https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags for other sample VAST ad tag URLs
static NSString * const kVASTOMAdTagURL = @"https://pubads.g.doubleclick.net/gampad/ads?iu=/124319096/external/omid_google_samples&env=vp&gdfp_req=1&output=vast&sz=640x480&description_url=http%3A%2F%2Ftest_site.com%2Fhomepage&tfcd=0&npa=0&vpmute=0&vpa=0&vad_format=linear&url=http%3A%2F%2Ftest_site.com&vpos=preroll&unviewed_position_start=1&correlator=";


@implementation VASTOMViewController

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

    IMASettings *imaSettings = [IMASettings new];
    imaSettings.language = NSLocale.currentLocale.languageCode;

    IMAAdsRenderingSettings *renderSettings = [IMAAdsRenderingSettings new];
    renderSettings.linkOpenerPresentingController = self;
    renderSettings.linkOpenerDelegate = self;
    
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
    NSDictionary *properties = @{ kBCOVIMAAdTag: kVASTOMAdTagURL };

    return [video update:^(BCOVMutableVideo* mutableVideo)
    {
        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
            [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd 
                                      position:kCMTimeZero
                                    properties:properties]
        ]];
    }];
}


#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
        didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    [super playbackController:controller
              playbackSession:session
           didEnterAdSequence:adSequence];

    IMAAdDisplayContainer *displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer];
    if (displayContainer)
    {
        UIView *transparentOverlay = self.playerView.overlayView;
        IMAFriendlyObstruction *overlayObstruction = [[IMAFriendlyObstruction alloc] initWithView:transparentOverlay
                                                                                          purpose:IMAFriendlyObstructionPurposeNotVisible
                                                                                   detailedReason:@"Transparent overlay does not impact viewability"];
        [displayContainer registerFriendlyObstruction:overlayObstruction];
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
         didExitAdSequence:(BCOVAdSequence *)adSequence
{
    [super playbackController:controller
              playbackSession:session
           didExitAdSequence:adSequence];

    IMAAdDisplayContainer *displayContainer = session.video.properties[kBCOVIMAVideoPropertiesKeyAdDisplayContainer];
    if (displayContainer)
    {
        [displayContainer unregisterAllFriendlyObstructions];
    }
}

@end
