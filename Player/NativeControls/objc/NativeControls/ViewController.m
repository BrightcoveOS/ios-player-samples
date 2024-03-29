//
//  ViewController.m
//  NativeControls
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import <AVKit/AVKit.h>

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) AVPlayerViewController *avpvc;

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
    _avpvc = [[AVPlayerViewController alloc] init];

    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createPlaybackController];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
    // since the AVPlayerViewController already makes one
    _playbackController.options = @{ kBCOVAVPlayerViewControllerCompatibilityKey: @YES };
    
    _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                            policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self addChildViewController:self.avpvc];
    [self.videoContainer addSubview:self.avpvc.view];
    self.avpvc.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.avpvc.view.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                              [self.avpvc.view.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                              [self.avpvc.view.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                              [self.avpvc.view.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                              ]];
    [self.avpvc didMoveToParentViewController:self];

    [self requestContentFromPlaybackService];
}

- (void)requestContentFromPlaybackService
{
    NSDictionary *configuration = @{kBCOVPlaybackServiceConfigurationKeyAssetID:kViewControllerVideoID};
    [self.playbackService findVideoWithConfiguration:configuration queryParameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
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

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
    self.avpvc.player = session.player;
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end


