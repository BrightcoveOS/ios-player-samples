//
//  VideoPropertiesViewController.m
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

#import "VideoPropertiesViewController.h"


@implementation VideoPropertiesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)setupPlaybackController
{
    id<BCOVPlaybackController> playbackController = ({
        IMASettings *imaSettings = [IMASettings new];
        imaSettings.language = NSLocale.currentLocale.localeIdentifier;
        IMAAdsRenderingSettings *adsRenderingSettings = [IMAAdsRenderingSettings new];
        adsRenderingSettings.linkOpenerDelegate = self;
        adsRenderingSettings.linkOpenerPresentingController = self;

        BCOVDAIAdsRequestPolicy *adsRequestPolicy = [BCOVDAIAdsRequestPolicy videoPropertiesAdsRequestPolicy];

        id<BCOVPlaybackSessionProvider> daiSessionProvider = [self.manager createDAISessionProviderWithSettings:imaSettings
                                                                                           adsRenderingSettings:adsRenderingSettings
                                                                                               adsRequestPolicy:adsRequestPolicy
                                                                                                    adContainer:self.playerView.contentOverlayView
                                                                                                 viewController:self
                                                                                                 companionSlots:nil
                                                                                        upstreamSessionProvider:nil
                                                                                                        options:nil];

        id<BCOVPlaybackController> playbackController = [self.manager createPlaybackControllerWithSessionProvider:daiSessionProvider
                                                                                                     viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoPlay = YES;
        playbackController.autoAdvance = YES;
        playbackController;
    });

    self.playerView.playbackController = playbackController;

    self.playbackController = playbackController;
}

- (BCOVVideo *)updateVideo:(BCOVVideo *)video
{
    BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo>  _Nonnull mutableVideo) {

        NSDictionary *adProperties = @{
            kBCOVDAIVideoPropertiesKeySourceId: kViewControllerGoogleDAISourceId,
            kBCOVDAIVideoPropertiesKeyVideoId: kViewControllerGoogleDAIVideoId
        };

        NSMutableDictionary *propertiesToUpdate = mutableVideo.properties.mutableCopy;
        [propertiesToUpdate addEntriesFromDictionary:adProperties];
        mutableVideo.properties = propertiesToUpdate;
    }];

    return updatedVideo;
}

@end
