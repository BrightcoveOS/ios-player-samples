//
//  ViewController.m
//  BasicOUXPlayer
//
//  Copyright (c) 2015 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

#import "BCOVPlayerSDK.h"
#import "BCOVOUX.h"

static NSString *kViewControllerVideoURLString = @"http://onceux.unicornmedia.com/now/ads/vmap/adaptive/m3u8/95ea75e1-dd2a-4aea-851a-28f46f8e8195/43f54cc0-aa6b-4b2c-b4de-63d707167bf9/9b118b95-38df-4b99-bb50-8f53d62f6ef8??umtp=0";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> controller;
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIView *companionSlotContainerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    // Create a companion slot.
    BCOVOUXCompanionSlot *companionSlot = [[BCOVOUXCompanionSlot alloc] initWithView:self.companionSlotContainerView width:300 height:250];
    
    // In order to display an ad progress banner on the top of the view, we create this display container.  This object is also responsible for populating the companion slots.
    BCOVOUXAdComponentDisplayContainer *adCompoentDisplayContainer = [[BCOVOUXAdComponentDisplayContainer alloc] initWithAdComponentContainer:self.videoContainerView companionSlots:@[companionSlot]];
    
    self.controller = [manager createOUXPlaybackControllerWithViewStrategy:[manager BCOVOUXdefaultControlsViewStrategy]];
    
    // In order for the ad display container to receive ad information, we add it as a session consumer.
    [self.controller addSessionConsumer:adCompoentDisplayContainer];
    
    self.controller.delegate = self;
    self.controller.autoPlay = YES;
    
    self.controller.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.controller.view.frame = self.videoContainerView.bounds;
    [self.videoContainerView addSubview:self.controller.view];
    
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
