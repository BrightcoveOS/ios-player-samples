//
//  ViewController.m
//  VideoCloudBasicPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"
#import "NowPlayingHandler.h"

@import BrightcovePlayerSDK;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (nonatomic, strong) NowPlayingHandler *nowPlayingHandler;

@end


@implementation ViewController

#pragma mark Setup Methods

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _playbackController = [BCOVPlayerSDKManager.sharedManager createPlaybackController];

    _playbackController.delegate = self;
    _playbackController.allowsExternalPlayback = YES;
    _playbackController.allowsBackgroundAudioPlayback = YES;
    _playbackController.autoPlay = YES;

    _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                            policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set up our player view. Create with a standard VOD layout.
    BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
    options.showPictureInPictureButton = YES;
    
    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout] ];
    playerView.delegate = self;

    [_videoContainer addSubview:playerView];
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [playerView.topAnchor constraintEqualToAnchor:_videoContainer.topAnchor],
                                              [playerView.rightAnchor constraintEqualToAnchor:_videoContainer.rightAnchor],
                                              [playerView.leftAnchor constraintEqualToAnchor:_videoContainer.leftAnchor],
                                              [playerView.bottomAnchor constraintEqualToAnchor:_videoContainer.bottomAnchor],
                                              ]];
    _playerView = playerView;

    // Associate the playerView with the playback controller.
    _playerView.playbackController = _playbackController;
    
    _nowPlayingHandler = [[NowPlayingHandler alloc] initWithPlaybackController:_playbackController];

    [self requestContentFromPlaybackService];
}

- (void)requestContentFromPlaybackService
{
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            [self.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }

    }];
}

#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"Advanced to new session.");
    
    // Enable route detection for AirPlay
    // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
    self.playerView.controlsView.routeDetector.routeDetectionEnabled = YES;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"Progress: %0.2f seconds", progress);
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventEnd])
    {
        // Disable route detection for AirPlay
        // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
        self.playerView.controlsView.routeDetector.routeDetectionEnabled = NO;
    }
}

#pragma mark - BCOVPUIPlayerViewDelegate

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerDidStartPictureInPicture");
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerDidStopPictureInPicture");
}

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerWillStartPictureInPicture");
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerWillStopPictureInPicture");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error
{
    NSLog(@"failedToStartPictureInPictureWithError: %@", error.localizedDescription);
}

@end
