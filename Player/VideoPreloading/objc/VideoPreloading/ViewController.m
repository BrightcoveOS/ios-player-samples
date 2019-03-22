//
//  ViewController.m
//  VideoPreloading
//
//  Created by Jeremy Blaker on 3/21/19.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"
#import "VideoPreloadManager.h"

@import BrightcovePlayerSDK;

static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerPlaylistRefID = @"brightcove-native-sdk-plist";

@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) VideoPreloadManager *videoPreloadManager;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;

@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@end


@implementation ViewController

#pragma mark Setup Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];
    
    [self setupPlayerView];
    
    self.videoPreloadManager = [[VideoPreloadManager alloc] initWithPlaybackControllerDelegate:self andPlayerView:self.playerView andShouldAutoPlay:YES];
    
    [self requestContentFromPlaybackService];
}

- (void)setupPlayerView
{
    // Set up our player view. Create with a standard VOD layout.
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:nil controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout]];
    
    [self.videoContainer addSubview:self.playerView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                              [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                              [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                              [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                              ]];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;
    [self.playbackService findPlaylistWithReferenceID:kViewControllerPlaylistRefID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (playlist.videos)
        {
            [strongSelf.videoPreloadManager setVideos:playlist.videos];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }
        
    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"Progress: %0.2f seconds", progress);
    [self.videoPreloadManager preloadNextVideoIfNeccessary:session];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd)
    {
        [self.videoPreloadManager currentVideoDidCompletePlayback];
    }
}

@end
