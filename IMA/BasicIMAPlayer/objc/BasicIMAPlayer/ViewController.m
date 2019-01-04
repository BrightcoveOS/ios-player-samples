//
//  ViewController.m
//  BasicIMAPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

@import GoogleInteractiveMediaAds;

@import BrightcovePlayerSDK;
@import BrightcoveIMA;


#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";

static NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
static NSString * const kViewControllerIMALanguage = @"en";
static NSString * const kViewControllerIMAVMAPResponseAdTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";


@interface ViewController () <BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, assign) BOOL isBrowserOpen;
@property (nonatomic, strong) id<NSObject> notificationReceipt;

@end


@implementation ViewController

#pragma mark Setup Methods

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_notificationReceipt];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self setup];
    [self requestContentFromPlaybackService];
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
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.videoContainer addSubview:self.playerView];
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
    [self createPlayerView];

    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];
    
    // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us to modify the IMAAdsRequest object
    // before it is used to load ads.
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };

    self.playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings
                                                          adsRenderingSettings:renderSettings
                                                              adsRequestPolicy:adsRequestPolicy
                                                                   adContainer:self.playerView.contentOverlayView
                                                                companionSlots:nil
                                                                  viewStrategy:nil
                                                                       options:imaPlaybackSessionOptions];
    self.playbackController.delegate = self;
    self.playbackController.autoAdvance = YES;
    self.playbackController.autoPlay = YES;

    self.playerView.playbackController = self.playbackController;

    // Creating a playback controller based on the above code will create
    // VMAP / Server Side Ad Rules. These settings are explained in BCOVIMAAdsRequestPolicy.h.
    // If you want to change these settings, you can initialize the plugin like so:
    //
    // BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:kViewControllerIMAVMAPResponseAdTag];
    //
    // or for VAST:
    //
    // BCOVCuePointProgressPolicy *policy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessFinalCuePoint
    //                                                                               resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead
    //                                                               ignoringPreviouslyProcessedCuePoints:NO];
    //
    // BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:policy];
    //
    // _playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings
    //                                                   adsRenderingSettings:renderSettings
    //                                                       adsRequestPolicy:adsRequestPolicy
    //                                                            adContainer:self.playerView.contentOverlayView
    //                                                         companionSlots:nil
    //                                                           viewStrategy:nil];
    //
    
    
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];

    [self resumeAdAfterForeground];
}

- (void)resumeAdAfterForeground
{
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.

    ViewController * __weak weakSelf = self;

    self.notificationReceipt = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {

        ViewController *strongSelf = weakSelf;

        if (strongSelf.adIsPlaying && !strongSelf.isBrowserOpen)
        {
            [strongSelf.playbackController resumeAd];
        }

    }];
}

- (void)requestContentFromPlaybackService
{
    // In order to play back content, we are going to request a playlist from the
    // playback service (Video Cloud Playback API). The data from the service does
    // not have the required VMAP tag on the video, so this code demonstrates how
    // to update a playlist to set the ad tags on the video. You are responsible
    // for determining where the ad tag should originate from. We advise that if
    // you choose to hard code it into your app, that you provide a mechanism to
    // update it without having to submit an update to your app.

    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        if (video)
        {
            BCOVPlaylist *playlist = [[BCOVPlaylist alloc] initWithVideo:video];
            
            BCOVPlaylist *updatedPlaylist = [playlist update:^(id<BCOVMutablePlaylist> mutablePlaylist) {

                NSMutableArray *updatedVideos = [NSMutableArray arrayWithCapacity:mutablePlaylist.videos.count];

                for (BCOVVideo *video in mutablePlaylist.videos)
                {
                    [updatedVideos addObject:[ViewController updateVideoWithVMAPTag:video]];
                }

                mutablePlaylist.videos = updatedVideos;

            }];

            [self.playbackController setVideos:updatedPlaylist.videos];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: %@", error);
        }
        
    }];
}

+ (BCOVVideo *)updateVideoWithVMAPTag:(BCOVVideo *)video
{
    // Update each video to add the tag.
    return [video update:^(id<BCOVMutableVideo> mutableVideo) {

        // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
        // the video's properties when using server side ad rules. This URL returns
        // a VMAP response that is handled by the Google IMA library.
        NSDictionary *adProperties = @{ kBCOVIMAAdTag : kViewControllerIMAVMAPResponseAdTag };

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

-(void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined BCOVIMAComponent.h.

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
