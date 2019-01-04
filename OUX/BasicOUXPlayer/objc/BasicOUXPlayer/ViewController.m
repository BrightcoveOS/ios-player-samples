//
//  ViewController.m
//  BasicOUXPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveOUX;

static NSString *kViewControllerVideoURLString = @"http://once.unicornmedia.com/now/ads/vmap/od/auto/c501c3ee-7f1c-4020-aa6d-0b1ef0bbd4a9/354a749c-217b-498e-b4f9-c48cd131f807/66496c0e-6969-41b1-859f-9bdf288cfdd3/content.once";


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
    [self.videoContainerView addSubview:self.playerView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
                                              [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
                                              [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
                                              [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
                                            ]];

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
