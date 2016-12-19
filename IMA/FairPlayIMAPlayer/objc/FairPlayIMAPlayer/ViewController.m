//
//  ViewController.m
//  FairPlayIMAPlayer
//
//  Copyright (c) 2016 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//
//  This sample app demonstrates how to set up the Brightcove SDK
//  to work with FairPlay-protected assets and IMA advertising.
//

@import GoogleInteractiveMediaAds;

@import BrightcoveFairPlay;
@import BrightcoveIMA;
@import BrightcovePlayerSDK;

#import "ViewController.h"


// Replace with your own IMA account info:
NSString * kViewControllerIMAPublisherID = @"insertyourpidhere";
NSString * kViewControllerIMALanguage = @"en";
NSString * kViewControllerIMAVMAPResponseAdTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";


// Replace with your own FairPlay account info:
NSString * kFairPlayPublisherId = @"00000000-0000-0000-0000-000000000000";
NSString * kFairPlayApplicationId = @"00000000-0000-0000-0000-000000000000";

// FairPlay-protected content URL
NSString * kFairPlayHLSVideoURL = @"http://example.com/fps/hlsvideo.m3u8";


@interface ViewController () <BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, strong) id<NSObject> notificationReceipt;

@end


@implementation ViewController

#pragma mark Setup Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
    [self setup];
}

- (void)setup
{
    NSLog(@"Setting up Brightcove objects");

    // Get the shared SDK manager
    BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];

    // IMA Settings
    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;

    // VMAP / Server Side Ad Rules. These settings are explained in BCOVIMAAdsRequestPolicy.h.
    // If you want to change these settings, you can initialize the plugin like so:
    //
    //    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];
    //
    // or for VAST:
    //
    //    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:[BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessAllCuePoints resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead ignoringPreviouslyProcessedCuePoints:YES]];

    // Use the VMAP ads policy.
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];


    // Create an authorization proxy for FairPlay
    // using the FairPlay Application ID and the FairPlay Publisher ID
    BCOVFPSBrightcoveAuthProxy *proxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:kFairPlayPublisherId
                                                                                  applicationId:kFairPlayApplicationId];

    // Retrieve the FairPlay application certificate
    NSLog(@"Retrieving FairPlay application certificate");
    [proxy retrieveApplicationCertificate:^(NSData * _Nullable applicationCertificate, NSError * _Nullable error) {

        if (applicationCertificate)
        {
            NSLog(@"Creating session providers");

            // We can create the FairPlay (and other session providers) now that we have the certificate
            id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:applicationCertificate
                                                                                                   authorizationProxy:proxy
                                                                                              upstreamSessionProvider:nil];

            // FairPlay is set as the upstream session provider when creating the IMA session provider.
            id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
                                                                                             adsRenderingSettings:renderSettings
                                                                                                 adsRequestPolicy:adsRequestPolicy
                                                                                                      adContainer:self.videoContainer
                                                                                                   companionSlots:nil
                                                                                          upstreamSessionProvider:fps];


            NSLog(@"Creating playback controller");
            // Create playback controller with the chain of session providers.
            id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:imaSessionProvider viewStrategy:nil];

            playbackController.delegate = self;
            playbackController.autoAdvance = YES;
            playbackController.autoPlay = YES;

            _playbackController = playbackController;

            // Match the parent view and install
            BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
            self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:_playbackController options:nil controlsView:controlView];
            _playerView.frame = self.videoContainer.bounds;
            _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [_videoContainer addSubview:self.playerView];

            _playerView.playbackController = _playbackController;

            NSLog(@"Created a new playbackController");

            [self requestContent];
        }
        else
        {
            NSLog(@"--- ERROR: FairPlay application certification not found ---");
        }

    }];

    [self resumeAdAfterForeground];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.notificationReceipt];
}

- (void)resumeAdAfterForeground
{
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.

    ViewController * __weak weakSelf = self;

    self.notificationReceipt =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {

                                                      ViewController *strongSelf = weakSelf;

                                                      if (strongSelf.adIsPlaying)
                                                      {
                                                          [strongSelf.playbackController resumeAd];
                                                      }

                                                  }];
}

- (void)requestContent
{
    NSLog(@"Request video content");

    // Here, you can retrieve BCOVVideo objects from the Playback Service. You can also
    // create your own BCOVVideo objects directly from URLs if you have them, as shown here:

    BCOVVideo *video = [BCOVVideo videoWithURL:[NSURL URLWithString:kFairPlayHLSVideoURL]];
    BCOVPlaylist *playlist = [[BCOVPlaylist alloc] initWithVideo:video];

    video = [self updateVideoWithVMAPTag:video];

    // The video does not have the required VMAP tag on the video, so this code demonstrates
    // how to update a playlist to set the ad tags on the video.
    // You are responsible for determining where the ad tag should originate from.
    // We advise that if you choose to hard code it into your app, that you provide
    // a mechanism to update it without having to submit an update to your app.
    BCOVPlaylist *updatedPlaylist = [playlist update:^(id<BCOVMutablePlaylist> mutablePlaylist) {

        NSMutableArray *updatedVideos = [NSMutableArray arrayWithCapacity:mutablePlaylist.videos.count];

        for (BCOVVideo *video in mutablePlaylist.videos)
        {
            // Add VMAP tag to video; see method below
            [updatedVideos addObject:[self updateVideoWithVMAPTag:video]];
        }

        mutablePlaylist.videos = updatedVideos;

    }];

    [self.playbackController setVideos:updatedPlaylist];
}

- (BCOVVideo *)updateVideoWithVMAPTag:(BCOVVideo *)video
{
    return [video update:^(id<BCOVMutableVideo> mutableVideo) {

        // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
        // the video's properties when using server side ad rules. This URL returns
        // a VMAP response that is handled by the Google IMA library.
        NSDictionary *adProperties =
        @{
          kBCOVIMAAdTag : kViewControllerIMAVMAPResponseAdTag
          };

        NSMutableDictionary *propertiesToUpdate = [mutableVideo.properties mutableCopy];
        [propertiesToUpdate addEntriesFromDictionary:adProperties];
        mutableVideo.properties = propertiesToUpdate;

    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined in BCOVIMAComponent.h.

    NSString *type = lifecycleEvent.eventType;

    if ([type isEqualToString:kBCOVIMALifecycleEventAdsLoaderLoaded])
    {
        NSLog(@"ViewController Debug - Ads loaded.");
    }
    else if ([type isEqualToString:kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];

        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                NSLog(@"ViewController Debug - Ad Started.");
                self.adIsPlaying = YES;
                break;
            case kIMAAdEvent_COMPLETE:
                NSLog(@"ViewController Debug - Ad Completed.");
                self.adIsPlaying = NO;
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController Debug - All ads completed.");
                break;
            default:
                break;
        }
    }
}

@end
