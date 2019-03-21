//
//  ViewController.m
//  BasicSSAIPlayer
//
//  Created by Jeremy Blaker on 3/18/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveOUX;

static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerVideoID = @"5702141808001";
static NSString * const kViewControllerAdConfigID = @"0e0bbcd1-bba0-45bf-a986-1288e5f9fc85";

@interface ViewController ()<BCOVPlaybackControllerDelegate, BCOVPlaybackControllerAdsDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIView *companionSlotContainerView;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVFPSBrightcoveAuthProxy *fairplayAuthProxy;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPlaybackController];
    [self setupPlayerView];
    [self setupPlaybackService];
    [self requestContentFromPlaybackService];
}

- (void)setupPlaybackController
{
    // Do any additional setup after loading the view, typically from a nib.
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    // Create a companion slot.
    BCOVOUXCompanionSlot *companionSlot = [[BCOVOUXCompanionSlot alloc] initWithView:self.companionSlotContainerView width:300 height:250];
    
    // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
    BCOVOUXAdComponentDisplayContainer *adComponentDisplayContainer = [[BCOVOUXAdComponentDisplayContainer alloc] initWithCompanionSlots:@[companionSlot]];
    
    self.fairplayAuthProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil applicationId:nil];
    
    id<BCOVPlaybackSessionProvider> fairplaySessionProvider = [manager createFairPlaySessionProviderWithAuthorizationProxy:self.fairplayAuthProxy upstreamSessionProvider:nil];
    id<BCOVPlaybackSessionProvider> ouxSessionProvider = [manager createOUXSessionProviderWithUpstreamSessionProvider:fairplaySessionProvider];
    
    self.playbackController = [manager createPlaybackControllerWithSessionProvider:ouxSessionProvider viewStrategy:nil];
    
    // In order for the ad display container to receive ad information, we add it as a session consumer.
    [self.playbackController addSessionConsumer:adComponentDisplayContainer];
    
    self.playbackController.delegate = self;
    self.playbackController.autoPlay = YES;
}

- (void)setupPlayerView
{
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:nil controlsView:controlView];
    
    [self.videoContainerView addSubview:self.playerView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
                                              [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
                                              [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
                                              [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
                                              ]];
}

- (void)setupPlaybackService
{
    BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kViewControllerAccountID policyKey:kViewControllerPlaybackServicePolicyKey baseURLStr:@"https://edge.api.brightcove.com/playback/v1"];
    self.playbackService = [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *queryParmaters = @{@"ad_config_id":kViewControllerAdConfigID};
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:queryParmaters completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            [weakSelf.playbackController setVideos:@[video]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video: %@", error.localizedDescription ?: @"unknown error");
        }
        
    }];
}

#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController Debug - Entering ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController Debug - Exiting ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAd:(BCOVAd *)ad
{
    NSLog(@"ViewController Debug - Entering ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAd:(BCOVAd *)ad
{
    NSLog(@"ViewController Debug - Exiting ad");
}

@end
