//
//  ViewController.m
//  CustomControls
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
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
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *standardVideoViewConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *fullscreenVideoViewConstraints;

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
    
    // Add the playbackController view
    // to videoView and setup its constraints
    [self.videoView addSubview:self.playbackController.view];
    self.playbackController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playbackController.view.topAnchor constraintEqualToAnchor:self.videoView.topAnchor],
                                              [self.playbackController.view.rightAnchor constraintEqualToAnchor:self.videoView.rightAnchor],
                                              [self.playbackController.view.leftAnchor constraintEqualToAnchor:self.videoView.leftAnchor],
                                              [self.playbackController.view.bottomAnchor constraintEqualToAnchor:self.videoView.bottomAnchor],
                                              ]];
    
    // Setup controlsViewController by
    // adding it as a child view controller,
    // adding its view as a subview of videoView
    // and adding its constraints
    [self addChildViewController:self.controlsViewController];
    [self.videoView addSubview:self.controlsViewController.view];
    [self.controlsViewController didMoveToParentViewController:self];
    self.controlsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.controlsViewController.view.topAnchor constraintEqualToAnchor:self.videoView.topAnchor],
                                              [self.controlsViewController.view.rightAnchor constraintEqualToAnchor:self.videoView.rightAnchor],
                                              [self.controlsViewController.view.leftAnchor constraintEqualToAnchor:self.videoView.leftAnchor],
                                              [self.controlsViewController.view.bottomAnchor constraintEqualToAnchor:self.videoView.bottomAnchor],
                                              ]];
    
    // Then add videoView as a subview of videoContainer
    [self.videoContainer addSubview:self.videoView];
    
    // Setup the standard view constraints
    // and activate them
    self.videoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.standardVideoViewConstraints = @[
                                          [self.videoView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                          [self.videoView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                          [self.videoView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                          [self.videoView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                          ];
    [NSLayoutConstraint activateConstraints:self.standardVideoViewConstraints];
    
    [self requestContentFromPlaybackService];
}

- (NSArray<NSLayoutConstraint *> *)fullscreenVideoViewConstraints
{
    if (!_fullscreenVideoViewConstraints) {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        if (@available(iOS 11, *))
        {
            insets = self.view.safeAreaInsets;
        }
        _fullscreenVideoViewConstraints = @[
                                            [self.videoView.topAnchor constraintEqualToAnchor:self.fullscreenViewController.view.topAnchor constant:insets.top],
                                                [self.videoView.rightAnchor constraintEqualToAnchor:self.fullscreenViewController.view.rightAnchor],
                                                [self.videoView.leftAnchor constraintEqualToAnchor:self.fullscreenViewController.view.leftAnchor],
                                                [self.videoView.bottomAnchor constraintEqualToAnchor:self.fullscreenViewController.view.bottomAnchor constant:-insets.bottom],
                                                ];
    }
    
    return _fullscreenVideoViewConstraints;
}

- (void)handleEnterFullScreenButtonPressed
{
    [self.fullscreenViewController addChildViewController:self.controlsViewController];
    [self.fullscreenViewController.view addSubview:self.videoView];
    [NSLayoutConstraint deactivateConstraints:self.standardVideoViewConstraints];
    [NSLayoutConstraint activateConstraints:self.fullscreenVideoViewConstraints];
    [self.controlsViewController didMoveToParentViewController:self.fullscreenViewController];
    
    [self presentViewController:self.fullscreenViewController animated:NO completion:nil];
}

- (void)handleExitFullScreenButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:^{
        
        [self addChildViewController:self.controlsViewController];
        [self.videoContainer addSubview:self.videoView];
        [NSLayoutConstraint deactivateConstraints:self.fullscreenVideoViewConstraints];
        [NSLayoutConstraint activateConstraints:self.standardVideoViewConstraints];
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
