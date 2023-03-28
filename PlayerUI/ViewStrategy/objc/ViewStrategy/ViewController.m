//
//  ViewController.m
//  ViewStrategy
//
//  Created by Carlos Ceja.
//  Copyright © 2020 Brightcove. All rights reserved.
//

@import BrightcovePlayerSDK;

#import "ViewController.h"

#import "ViewStrategyCustomControls.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@end


@implementation ViewController

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
}


#pragma mark Misc

- (void)setup
{
    [self createPlaybackController];
    
    [self requestVideo];

}

- (void)createPlaybackController
{
    if (!self.playbackController)
    {
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        
        BCOVPlaybackControllerViewStrategy viewStrategy = ^UIView *(UIView *videoView, id<BCOVPlaybackController> playbackController)
        {
            // Create some custom controls for the video view,
            // and compose both into a container view.
            UIView *controlsAndVideoView = [[UIView alloc] initWithFrame:CGRectZero];
            
            ViewStrategyCustomControls *controlsView = [[ViewStrategyCustomControls alloc] initWithPlaybackController:playbackController];

            [controlsAndVideoView addSubview:videoView];
            [controlsAndVideoView addSubview:controlsView];
            
            videoView.frame = controlsAndVideoView.bounds;
            
            [playbackController addSessionConsumer:controlsView];
    
            return controlsAndVideoView;
        };

        self.playbackController = [manager createPlaybackControllerWithViewStrategy:viewStrategy];
        
        self.playbackController.autoPlay = YES;
        self.playbackController.autoAdvance = YES;
        self.playbackController.delegate = self;
        
        self.playbackController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.videoContainer addSubview:self.playbackController.view];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.playbackController.view.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
            [self.playbackController.view.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
            [self.playbackController.view.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
            [self.playbackController.view.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
        ]];
    }
    else
    {
        NSLog(@"PlaybackController already exists");
    }
}

- (void)requestVideo
{
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID policyKey:kViewControllerPlaybackServicePolicyKey];

    __weak typeof(self) weakSelf = self;
    
    NSDictionary *configuration = @{kBCOVPlaybackServiceConfigurationKeyAssetID:kViewControllerVideoID};
    [self.playbackService findVideoWithConfiguration:configuration queryParameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        if (video)
        {
            [weakSelf.playbackController setVideos:@[ video ]];
        }
        else
        {
             NSLog(@"PlayerViewController Debug - Error retrieving video");
        }

    }];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"Event: %@", lifecycleEvent.eventType);
}

@end
