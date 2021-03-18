//
//  ViewController.m
//  FairPlayIMAPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//
//  This sample app demonstrates how to set up the Brightcove SDK
//  to work with FairPlay-protected assets and IMA advertising.
//

@import GoogleInteractiveMediaAds;

@import BrightcoveIMA;
@import BrightcovePlayerSDK;
@import AppTrackingTransparency;

#import "ViewController.h"


// Replace with your own IMA account info:
NSString * kViewControllerIMAPublisherID = @"insertyourpidhere";
NSString * kViewControllerIMALanguage = @"en";
NSString * kViewControllerIMAVMAPResponseAdTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";


// Replace with your own FairPlay account info:
NSString * kFairPlayPublisherId = @"00000000-0000-0000-0000-000000000000";
NSString * kFairPlayApplicationId = @"00000000-0000-0000-0000-000000000000";

// FairPlay-protected content URL
NSString * kFairPlayHLSVideoURL = @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8";


@interface ViewController () <BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
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
    
    if (@available(iOS 14, *))
    {
        __weak typeof(self) weakSelf = self;
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed. Start loading ads here.
                [strongSelf setup];
            });
        }];
    }
    else
    {
        [self setup];
    }
    
    // FairPlay doesn't work when we're running in a simulator, so put up an alert.
#if (TARGET_OS_SIMULATOR)
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FairPlay Warning"
                                                                   message:@"FairPlay only works on actual iOS devices, not in a simulator.\n\nYou will not be able to view any FairPlay content."
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault  handler:^(UIAlertAction *action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];

#endif
}

- (void)createPlayerView
{
    if (!self.playerView)
    {
        BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
        options.presentingViewController = self;
        
        BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
        // Set playback controller later.
        self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:controlView];
        [self.videoContainer addSubview:self.playerView];
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                                  [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                                  [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                                  [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                                ]];
    }
    else
    {
        NSLog(@"PlayerView already exists");
    }
}

- (void)setup
{
    NSLog(@"Setting up Brightcove objects");

    [self createPlayerView];

    // Get the shared SDK manager
    BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
    
    // This shows the two ways of using the Brightcove FairPlay session provider:
    // Set to true for Dynamic Delivery; false for a legacy Video Cloud account
    BOOL using_dynamic_delivery = YES;
    
    if (using_dynamic_delivery)
    {
        // If you're using Dynamic Delivery, you don't need to load
        // an application certificate. The FairPlay session will load an
        // application certificate for you if needed.
        // You can just load and play your FairPlay videos.
        
        // Create an authorization proxy for FairPlay
       // with dynamic delivery you do not need to pass in publisher ID or application ID
        BCOVFPSBrightcoveAuthProxy *proxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                      applicationId:nil];
        
        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                               authorizationProxy:proxy
                                                                                          upstreamSessionProvider:nil];
        [self setupPlaybackControllerWithFPSessionProvider:fps];
    }
    else
    {
        // Legacy Video Cloud account
        
        // You can create your FairPlay session provider first, and give it an
        // application certificate later, but in this application we want to play
        // right away, so it's easier to load our player as soon as we know
        // that we have an application certificate
        
        // Create an authorization proxy for FairPlay
        // using the FairPlay Application ID and the FairPlay Publisher ID
        BCOVFPSBrightcoveAuthProxy *proxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:kFairPlayPublisherId
                                                                                      applicationId:kFairPlayApplicationId];
        
        // Retrieve the FairPlay application certificate
        NSLog(@"Retrieving FairPlay application certificate");
        
        __weak typeof(self) weakSelf = self;
        [proxy retrieveApplicationCertificate:^(NSData * _Nullable applicationCertificate, NSError * _Nullable error) {

            if (applicationCertificate)
            {
                NSLog(@"Creating session providers");

                // We can create the FairPlay (and other session providers) now that we have the certificate
                id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:applicationCertificate
                                                                                                       authorizationProxy:proxy
                                                                                                  upstreamSessionProvider:nil];
                
                [weakSelf setupPlaybackControllerWithFPSessionProvider:fps];
            }
            else
            {
                NSLog(@"--- ERROR: FairPlay application certificate not found ---");
            }

        }];
    }

    [self resumeAdAfterForeground];
}

- (void)setupPlaybackControllerWithFPSessionProvider:(id<BCOVPlaybackSessionProvider>)fps
{
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

    // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us
    // to modify the IMAAdsRequest object before it is used to load ads.
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };
    
    // FairPlay is set as the upstream session provider when creating the IMA session provider.
    id<BCOVPlaybackSessionProvider> imaSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings
                                                                                     adsRenderingSettings:renderSettings
                                                                                         adsRequestPolicy:adsRequestPolicy
                                                                                              adContainer:self.playerView.contentOverlayView
                                                                                           viewController:self
                                                                                           companionSlots:nil
                                                                                  upstreamSessionProvider:fps
                                                                                                  options:imaPlaybackSessionOptions];

    NSLog(@"Creating playback controller");
    
    // Create playback controller with the chain of session providers.
    id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:imaSessionProvider
                                                                                               viewStrategy:nil];
    
    playbackController.delegate = self;
    playbackController.autoAdvance = YES;
    playbackController.autoPlay = YES;

    self.playbackController = playbackController;

    self.playerView.playbackController = playbackController;

    NSLog(@"Created a new playbackController");

    [self requestContent];
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

    // Here, you can retrieve BCOVVideo objects from the Playback Service, alternatively you may
    // create your own BCOVVideo objects directly from URLs if you have them.
    // You can see an example of both methods below. Simply change `usePlaybackService` to
    // YES or NOR depending on which method you want to use.
    
    BOOL usePlaybackService = YES;
    
    if (usePlaybackService)
    {
        self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                    policyKey:kViewControllerPlaybackServicePolicyKey];
        
        [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
           
            if (error)
            {
                NSLog(@"ViewController Debug - Error retrieving video: %@", error);
            }
            else
            {
                video = [self updateVideoWithVMAPTag:video];
                [self.playbackController setVideos:@[video]];
            }
            
        }];
    }
    else
    {
        BCOVVideo *video = [BCOVVideo videoWithHLSSourceURL:[NSURL URLWithString:kFairPlayHLSVideoURL]];
        video = [self updateVideoWithVMAPTag:video];

        [self.playbackController setVideos:@[video]];
    }

}

- (BCOVVideo *)updateVideoWithVMAPTag:(BCOVVideo *)video
{
    // The video does not have the required VMAP tag on the video, so this code demonstrates
    // how to update a video to set the ad tags on the video.
    // You are responsible for determining where the ad tag should originate from.
    // We advise that if you choose to hard code it into your app, that you provide
    // a mechanism to update it without having to submit an update to your app.

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

#pragma mark - BCOVPlaybackControllerDelegate Methods

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

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    // Hide all controls for ads (so they're not visible when full-screen)
    self.playerView.controlsContainerView.alpha = 0.0;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence
{
    // Show all controls when ads are finished.
    self.playerView.controlsContainerView.alpha = 1.0;
}

#pragma mark - IMAPlaybackSessionDelegate Methods

- (void)willCallIMAAdsLoaderRequestAdsWithRequest:(IMAAdsRequest *)adsRequest forPosition:(NSTimeInterval)position
{
    // for demo purposes, increase the VAST ad load timeout.
    adsRequest.vastLoadTimeout = 3000.;
    NSLog(@"ViewController Debug - IMAAdsRequest.vastLoadTimeout set to %.1f milliseconds.", adsRequest.vastLoadTimeout);
}

#pragma mark - IMAWebOpenerDelegate Methods

- (void)webOpenerDidCloseInAppBrowser:(NSObject *)webOpener
{
    // Called when the in-app browser has closed.
    [self.playbackController resumeAd];
}

@end
