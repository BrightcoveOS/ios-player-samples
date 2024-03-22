//
//  ViewController.m
//  NativeControlsIMAPlayer_tvOS
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>
#import <BrightcoveIMA/BrightcoveIMA.h>

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";

static NSString * const kVMAPAdTagURL = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";


@interface ViewController() <BCOVPlaybackControllerDelegate, BCOVIMAPlaybackSessionDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) AVPlayerViewController *avpvc;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setup];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(requestTrackingAuthorization)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)setup
{
    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.avpvc = ({
        AVPlayerViewController *avpvc = [AVPlayerViewController new];
        [self addChildViewController:avpvc];
        [self.view addSubview:avpvc.view];
        avpvc.view.frame = self.view.bounds;
        [avpvc didMoveToParentViewController:self];

        avpvc;
    });

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        IMASettings *imaSettings = [IMASettings new];
        imaSettings.language = NSLocale.currentLocale.languageCode;

        IMAAdsRenderingSettings *renderSettings = [IMAAdsRenderingSettings new];

        BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];

        // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition:
        // which allows us to modify the IMAAdsRequest object before it is used to load ads.
        NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };

        id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
                                                                                         adsRenderingSettings:renderSettings
                                                                                             adsRequestPolicy:adsRequestPolicy
                                                                                                  adContainer:self.avpvc.contentOverlayView
                                                                                               viewController:self.avpvc
                                                                                               companionSlots:nil
                                                                                      upstreamSessionProvider:fps
                                                                                                      options:imaPlaybackSessionOptions];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:imaSessionProvider
                                                                                                   viewStrategy:nil];

        playbackController.options = @{ kBCOVAVPlayerViewControllerCompatibilityKey: @(YES) };

        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        playbackController;
    });
}

- (void)requestTrackingAuthorization
{
    if (@available(tvOS 14.5, *))
    {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            switch (status)
            {
                case ATTrackingManagerAuthorizationStatusAuthorized:
                    NSLog(@"Authorized Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusDenied:
                    NSLog(@"Denied Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusNotDetermined:
                    NSLog(@"Not Determined Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusRestricted:
                    NSLog(@"Restricted Tracking Permission");
                    break;
            }

            NSLog(@"IDFA: %@", ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString);

            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed.
                // Start loading ads here.
                [self requestContentFromPlaybackService];
            });

        }];
    }
    else
    {
        [self requestContentFromPlaybackService];
    }

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId };
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
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                });

                return;
            }
#endif

            [strongSelf.playbackController setVideos:@[[strongSelf updateVideoWithVMAPTag:video]]];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }

    }];
}

- (BCOVVideo *)updateVideoWithVMAPTag:(BCOVVideo *)video
{
    return [video update:^(id<BCOVMutableVideo> mutableVideo) {

        // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
        // the video's properties when using server side ad rules. This URL returns
        // a VMAP response that is handled by the Google IMA library.
        NSDictionary *adProperties = @{ kBCOVIMAAdTag: kVMAPAdTagURL };

        NSMutableDictionary *propertiesToUpdate = mutableVideo.properties.mutableCopy;
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
        [metadataArray addObject:[self makeMetadataItem:AVMetadataCommonIdentifierTitle
                                                  value:title]];
    }

    // Desc
    NSString *desc = [video.properties[kBCOVVideoPropertyKeyDescription] copy];
    if (desc)
    {
        [metadataArray addObject:[self makeMetadataItem:AVMetadataCommonIdentifierDescription
                                                  value:desc]];
    }

    // Poster
    NSString *posterURLString = [video.properties[kBCOVVideoPropertyKeyPoster] copy];
    NSURL *posterURL = [NSURL URLWithString:posterURLString];
    if (posterURL)
    {
        NSData *posterData = [NSData dataWithContentsOfURL:posterURL];
        [metadataArray addObject:[self makeMetadataItem:AVMetadataCommonIdentifierArtwork
                                                  value:posterData]];
    }

    return metadataArray;
}

- (AVMetadataItem *)makeMetadataItem:(AVMetadataIdentifier)identifier
                               value:(id)value
{
    AVMutableMetadataItem *item = [AVMutableMetadataItem new];
    item.identifier = identifier;
    item.value = value;
    item.extendedLanguageTag = @"und";
    return item.copy;
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");

    BCOVVideo *video = session.video;
    AVPlayer *player = session.player;

    // Set the external metadata for the info view
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        player.currentItem.externalMetadata = [self buildMetadataForVideo:video];
    });

    // Set the player on the AVPlayerViewController to begin playback
    self.avpvc.player = player;
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

    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined BCOVIMAComponent.h.
    if ([kBCOVIMALifecycleEventAdsLoaderLoaded isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"ViewController - Ads loaded.");

        IMAAdsManager *adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager];
        if (adsManager)
        {
            // Lower the volume of ads by half.
            adsManager.volume = adsManager.volume / 2.0;
            NSLog (@"ViewController - IMAAdsManager.volume set to %0.1f.", adsManager.volume);
        }
    }
    else if ([kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent isEqualToString:lifecycleEvent.eventType])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];
        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                NSLog(@"ViewController - Ad Started.");
                break;
            case kIMAAdEvent_COMPLETE:
                NSLog(@"ViewController - Ad Completed.");
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController - All ads completed.");
                break;
            default:
                break;
        }
    }
}


#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
        didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController - Entering ad sequence");
    self.avpvc.showsPlaybackControls = NO;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
         didExitAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController - Exiting ad sequence");
    self.avpvc.showsPlaybackControls = YES;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
                didEnterAd:(BCOVAd *)ad
{
    NSLog(@"ViewController - Entering ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
                 didExitAd:(BCOVAd *)ad
{
    NSLog(@"ViewController - Exiting ad");
}


#pragma mark - BCOVIMAPlaybackSessionDelegate

- (void)willCallIMAAdsLoaderRequestAdsWithRequest:(IMAAdsRequest *)adsRequest
                                      forPosition:(NSTimeInterval)position
{
    // for demo purposes, increase the VAST ad load timeout.
    adsRequest.vastLoadTimeout = 3000.;
    NSLog(@"ViewController - IMAAdsRequest.vastLoadTimeout set to %.1f milliseconds.", adsRequest.vastLoadTimeout);
}

@end
