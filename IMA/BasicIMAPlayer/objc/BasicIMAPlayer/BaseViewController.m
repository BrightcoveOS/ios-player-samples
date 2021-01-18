//
//  BaseViewController.m
//  BasicIMAPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

@import GoogleInteractiveMediaAds;
@import BrightcovePlayerSDK;
@import BrightcoveIMA;
@import AppTrackingTransparency;

#import "BaseViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";

NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
NSString * const kViewControllerIMALanguage = @"en";

@interface BaseViewController ()

@property (nonatomic, strong) BCOVPlaybackService *playbackService;

@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, assign) BOOL isBrowserOpen;
@property (nonatomic, strong) id<NSObject> notificationReceipt;

@end


@implementation BaseViewController

#pragma mark Setup Methods

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_notificationReceipt];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(iOS 14, *))
    {
        __weak typeof(self) weakSelf = self;
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                // Tracking authorization completed. Start loading ads here.
                [strongSelf setup];
                [strongSelf requestContentFromPlaybackService];
            });
        }];
    }
    else
    {
        [self setup];
        [self requestContentFromPlaybackService];
    }
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

- (void)setupPlaybackController
{
    // NO-OP
    // Override this method in subclasses
}

- (BCOVVideo *)updateVideo:(BCOVVideo *)video
{
    // NO-OP
    // Override this method in subclasses
    return nil;
}

- (void)setup
{
    [self createPlayerView];
    
    [self setupPlaybackController];
    
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];

    [self resumeAdAfterForeground];
}

- (void)resumeAdAfterForeground
{
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.

    BaseViewController * __weak weakSelf = self;

    self.notificationReceipt = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {

        BaseViewController *strongSelf = weakSelf;

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
                    [updatedVideos addObject:[self updateVideo:video]];
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

#pragma mark - BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
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
