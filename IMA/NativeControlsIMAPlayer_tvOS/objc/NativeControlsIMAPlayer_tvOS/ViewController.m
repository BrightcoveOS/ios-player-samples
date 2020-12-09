//
//  ViewController.m
//  NativeControlsIMAPlayer_tvOS
//
//  Created by Jeremy Blaker on 6/1/20.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveIMA;
@import AVKit;
@import GoogleInteractiveMediaAds;
@import AppTrackingTransparency;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";

NSString * kViewControllerIMAPublisherID = @"insertyourpidhere";
NSString * kViewControllerIMALanguage = @"en";
NSString * kViewControllerIMAVMAPResponseAdTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";

@interface ViewController ()<BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) AVPlayerViewController *avpvc;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupPlayerViewController];
    [self setupPlaybackService];
    [self setupPlaybackController];
    
    if (@available(tvOS 14, *))
    {
        __weak typeof(self) weakSelf = self;
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed. Start loading ads here.
                [strongSelf requestContentFromPlaybackService];
            });
        }];
    }
    else
    {
        [self requestContentFromPlaybackService];
    }
}

#pragma mark - Setup

- (void)setupPlaybackController
{
    // IMA Settings
    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    
    BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
    
    // Use the VMAP ads policy.
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];

    // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us
    // to modify the IMAAdsRequest object before it is used to load ads.
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };
    
    id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
                                                                                     adsRenderingSettings:renderSettings
                                                                                         adsRequestPolicy:adsRequestPolicy
                                                                                              adContainer:self.avpvc.contentOverlayView
                                                                                           viewController:self.avpvc
                                                                                           companionSlots:nil
                                                                                  upstreamSessionProvider:nil
                                                                                                  options:imaPlaybackSessionOptions];

    self.playbackController = [sdkManager createPlaybackControllerWithSessionProvider:imaSessionProvider viewStrategy:nil];
    self.playbackController.delegate = self;
    self.playbackController.autoAdvance = YES;
    self.playbackController.autoPlay = YES;

    // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
    // since the AVPlayerViewController already makes one
    self.playbackController.options = @{ kBCOVAVPlayerViewControllerCompatibilityKey: @YES };
}

- (void)setupPlaybackService
{
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)setupPlayerViewController
{
    self.avpvc = [AVPlayerViewController new];
    
    [self addChildViewController:self.avpvc];
    [self.view addSubview:self.avpvc.view];
    self.avpvc.view.frame = self.view.frame;
    [self.avpvc didMoveToParentViewController:self];
}

#pragma mark - Private

- (void)requestContentFromPlaybackService
{
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            [self.playbackController setVideos:@[ [self updateVideoWithVMAPTag:video] ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video: `%@`", error);
        }

    }];
}

- (BCOVVideo *)updateVideoWithVMAPTag:(BCOVVideo *)video
{
    return [video update:^(id<BCOVMutableVideo> mutableVideo) {

        // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
        // the video's properties when using server side ad rules. This URL returns
        // a VMAP response that is handled by the Google IMA library.
        NSDictionary *adProperties = @{
            kBCOVIMAAdTag : kViewControllerIMAVMAPResponseAdTag
        };

        NSMutableDictionary *propertiesToUpdate = [mutableVideo.properties mutableCopy];
        [propertiesToUpdate addEntriesFromDictionary:adProperties];
        mutableVideo.properties = propertiesToUpdate;

    }];
}

- (NSArray *)buildMetadataForVideo:(BCOVVideo *)video
{
    // https://developer.apple.com/documentation/avkit/adding_information_to_the_info_panel_tvos/presenting_metadata_in_the_tvos_info_panel
    
    NSMutableArray *metadataArray = @[].mutableCopy;
    
    // Title
    NSString *title = [video.properties[kBCOVVideoPropertyKeyName] copy];
    if (title)
    {
        [metadataArray addObject:[self makeMetadataItem:AVMetadataCommonIdentifierTitle value:title]];
    }
    
    // Desc
    NSString *desc = [video.properties[kBCOVVideoPropertyKeyDescription] copy];
    if (desc)
    {
        [metadataArray addObject:[self makeMetadataItem:AVMetadataCommonIdentifierDescription value:desc]];
    }
    
    // Poster
    NSString *posterURLString = [video.properties[kBCOVVideoPropertyKeyPoster] copy];
    NSURL *posterURL = [NSURL URLWithString:posterURLString];
    if (posterURL)
    {
        NSData *posterData = [NSData dataWithContentsOfURL:posterURL];
        [metadataArray addObject:[self makeMetadataItem:AVMetadataCommonIdentifierArtwork value:posterData]];
    }
    
    return metadataArray;
}

- (AVMetadataItem *)makeMetadataItem:(AVMetadataIdentifier)identifier value:(id)value
{
    AVMutableMetadataItem *item = [AVMutableMetadataItem new];
    item.identifier = identifier;
    item.value = value;
    item.extendedLanguageTag = @"und";
    return item.copy;
}

#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    BCOVVideo *video = session.video;
    AVPlayer *player = session.player;
    
    // Set the external metadata for the info view
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        player.currentItem.externalMetadata = [self buildMetadataForVideo:video];
    });
    
    // Set the player on the AVPlayerViewController to begin playback
    self.avpvc.player = player;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined in BCOVIMAComponent.h.

    NSString *type = lifecycleEvent.eventType;

    if ([type isEqualToString:kBCOVIMALifecycleEventAdsLoaderLoaded])
    {
        NSLog(@"ViewController Debug - Ads loaded.");
        
        // When ads load successfully, the kBCOVIMALifecycleEventAdsLoaderLoaded lifecycle event
        // returns an NSDictionary containing a reference to the IMAAdsManager.
        IMAAdsManager *adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager];
        if (adsManager != nil)
        {
            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0;
            NSLog (@"ViewController Debug - IMAAdsManager.volume set to %0.1f.", adsManager.volume);
        }
    }
    else if ([type isEqualToString:kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];

        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                NSLog(@"ViewController Debug - Ad Started.");
                break;
            case kIMAAdEvent_COMPLETE:
                NSLog(@"ViewController Debug - Ad Completed.");
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController Debug - All ads completed.");
                break;
            default:
                break;
        }
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    self.avpvc.showsPlaybackControls = NO;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence
{
    self.avpvc.showsPlaybackControls = YES;
}

#pragma mark - BCOVIMAPlaybackSessionDelegate Methods

- (void)willCallIMAAdsLoaderRequestAdsWithRequest:(IMAAdsRequest *)adsRequest forPosition:(NSTimeInterval)position
{
    // for demo purposes, increase the VAST ad load timeout.
    adsRequest.vastLoadTimeout = 3000.;
    NSLog(@"ViewController Debug - IMAAdsRequest.vastLoadTimeout set to %.1f milliseconds.", adsRequest.vastLoadTimeout);
}

@end
