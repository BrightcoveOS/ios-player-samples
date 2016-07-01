//
//  ViewController.m
//  BasicOUXPlayer
//
//  Copyright (c) 2015 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveOUX;

static NSString *kViewControllerVideoURLString = @"http://onceux.unicornmedia.com/now/ads/vmap/od/auto/c6589dd5-8f31-4ae3-8a5f-a54ca3d7c973/632f6399-9e87-4ce2-a7c0-39209be2b5d0/bee45a63-71ea-4a20-800f-b67091867eeb/content.once";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> controller;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIView *companionSlotContainerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    // Create a companion slot.
    BCOVOUXCompanionSlot *companionSlot = [[BCOVOUXCompanionSlot alloc] initWithView:self.companionSlotContainerView width:500 height:61];
    
    // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
    BCOVOUXAdComponentDisplayContainer *adComponentDisplayContainer = [[BCOVOUXAdComponentDisplayContainer alloc] initWithCompanionSlots:@[companionSlot]];
    
    self.controller = [manager createOUXPlaybackControllerWithViewStrategy:nil];
    
    // In order for the ad display container to receive ad information, we add it as a session consumer.
    [self.controller addSessionConsumer:adComponentDisplayContainer];
    
    self.controller.delegate = self;
    self.controller.autoPlay = YES;

    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    // Set playback controller later.
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:nil controlsView:controlView];
    self.playerView.frame = self.videoContainerView.bounds;
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainerView addSubview:self.playerView];

    self.playerView.playbackController = self.controller;

    // Create video
    BCOVVideo *video = [BCOVVideo videoWithURL:[NSURL URLWithString:kViewControllerVideoURLString]];
    [self.controller setVideos:@[video]];
}


#pragma mark BCOVPlaybackControllerBasicDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}


#pragma mark BCOVPlaybackControllerAdsDelegate

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
