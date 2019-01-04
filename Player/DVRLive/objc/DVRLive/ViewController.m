//
//  ViewController.m
//  VideoCloudBasicPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

@import BrightcovePlayerSDK;


static NSString * const kVideoURLString = <URL of Live HLS>;

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

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
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createPlaybackControllerWithViewStrategy:nil];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;

    BCOVPUIBasicControlView *controlsView = [BCOVPUIBasicControlView basicControlViewWithLiveDVRLayout];

    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:controlsView ];
    playerView.delegate = self;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [_videoContainer addSubview:playerView];
    [NSLayoutConstraint activateConstraints:@[
                                              [playerView.topAnchor constraintEqualToAnchor:_videoContainer.topAnchor],
                                              [playerView.rightAnchor constraintEqualToAnchor:_videoContainer.rightAnchor],
                                              [playerView.leftAnchor constraintEqualToAnchor:_videoContainer.leftAnchor],
                                              [playerView.bottomAnchor constraintEqualToAnchor:_videoContainer.bottomAnchor],
                                              ]];
    _playerView = playerView;
    _playerView.playbackController = _playbackController;

    NSURL *videoURL = [NSURL URLWithString:kVideoURLString];
    BCOVSource *source = [[BCOVSource alloc] initWithURL:videoURL deliveryMethod:kBCOVSourceDeliveryHLS properties:nil];
    BCOVVideo *video = [[BCOVVideo alloc] initWithSource:source cuePoints:nil properties:nil];
    [self.playbackController setVideos:@[video]];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventPlay])
    {
        NSLog(@"ViewController Debug - Received lifecycle play event.");
    }
    else if([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventPause])
    {
        NSLog(@"ViewController Debug - Received lifecycle pause event.");
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

