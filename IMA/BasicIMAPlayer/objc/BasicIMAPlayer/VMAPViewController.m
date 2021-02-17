//
//  VMAPViewController.m
//  BasicIMAPlayer
//
//  Created by Jeremy Blaker on 10/23/20.
//  Copyright © 2020 BrightCove. All rights reserved.
//

#import "VMAPViewController.h"

// See https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags for other sample VMAP ad tag URLs
static NSString * const kVMAPAdTagURL = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator=";

@interface VMAPViewController ()<BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@property (nonatomic, assign) BOOL useVideoProperties;

@end

@implementation VMAPViewController

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = NSLocale.currentLocale.languageCode;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    // BCOVIMAAdsRequestPolicy provides two VMAP configurations:
    // `videoPropertiesVMAPAdTagUrlAdsRequestPolicy` and
    // `adsRequestPolicyWithVMAPAdTagUrl:`
    //
    // Using `videoPropertiesVMAPAdTagUrlAdsRequestPolicy` allows you to
    // set a different VMAP ad tag URL for each video, while using
    // `adsRequestPolicyWithVMAPAdTagUrl:` will use the same VMAP ad tag URL
    // for each video.
    
    self.useVideoProperties = YES;
    
    BCOVIMAAdsRequestPolicy *adsRequestPolicy;
    
    if (self.useVideoProperties)
    {
        adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];
    }
    else
    {
        adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:kVMAPAdTagURL];
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
    if (self.useVideoProperties)
    {
        // Update each video to add the tag.
        return [video update:^(id<BCOVMutableVideo> mutableVideo) {

            // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
            // the video's properties when using ad rules. This URL returns
            // a VMAP response that is handled by the Google IMA library.
            NSDictionary *adProperties = @{ kBCOVIMAAdTag : kVMAPAdTagURL };

            NSMutableDictionary *propertiesToUpdate = [mutableVideo.properties mutableCopy];
            [propertiesToUpdate addEntriesFromDictionary:adProperties];
            mutableVideo.properties = propertiesToUpdate;

        }];
    }
    
    return video;
}

@end
