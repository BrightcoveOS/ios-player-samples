//
//  ViewController.m
//  CustomControls
//
//  Copyright © 2017 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"

#import "ControlsViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";


@interface ViewController () <BCOVPlaybackControllerDelegate, ControlsViewControllerFullScreenDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) ControlsViewController *controlsViewController;
@property (nonatomic, strong) UIViewController *fullscreenViewController;

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
    _videoView = [[UIView alloc] init];
    _fullscreenViewController = [[UIViewController alloc] init];
    _controlsViewController = [[ControlsViewController alloc] init];
    _controlsViewController.delegate = self;

    _playbackController = [[BCOVPlayerSDKManager sharedManager] createPlaybackController];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;
    [_playbackController setAllowsExternalPlayback:YES];
    [_playbackController addSessionConsumer:_controlsViewController];

    _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                            policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.playbackController.view.frame = self.videoView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoView addSubview:self.playbackController.view];

    [self addChildViewController:self.controlsViewController];
    self.controlsViewController.view.frame = self.videoView.bounds;
    [self.videoView addSubview:self.controlsViewController.view];
    [self.controlsViewController didMoveToParentViewController:self];

    self.videoView.frame = self.videoContainer.bounds;
    self.videoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer addSubview:self.videoView];

    [self requestContentFromPlaybackService];
}

- (void)handleEnterFullScreenButtonPressed
{
    [self.fullscreenViewController addChildViewController:self.controlsViewController];
    self.videoView.frame = self.fullscreenViewController.view.bounds;
    [self.fullscreenViewController.view addSubview:self.videoView];
    [self.controlsViewController didMoveToParentViewController:self.fullscreenViewController];

    [self presentViewController:self.fullscreenViewController animated:NO completion:nil];
}

- (void)handleExitFullScreenButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:^{

        self.videoView.frame = self.videoContainer.bounds;
        [self addChildViewController:self.controlsViewController];
        [self.videoContainer addSubview:self.videoView];
        [self.controlsViewController didMoveToParentViewController:self];

    }];
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

#pragma mark BCOVPlaybackControllerDelegate

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
