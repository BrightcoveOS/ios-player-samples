//
//  ViewController.m
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "ControlsViewController.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"5702141808001";


@interface ViewController () <BCOVPlaybackControllerDelegate, ControlsViewControllerFullScreenDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) ControlsViewController *controlsViewController;
@property (nonatomic, strong) UIViewController *fullscreenViewController;

@end


@implementation ViewController

//- (void)setup
//{
//    _videoView = [[UIView alloc] init];
//    _fullscreenViewController = [[UIViewController alloc] init];
//    _controlsViewController = [[ControlsViewController alloc] init];
//    _controlsViewController.delegate = self;
//

//}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.controlsViewController = ({
        ControlsViewController *controlsViewController = [ControlsViewController new];
        controlsViewController.delegate = self;
        controlsViewController;
    });

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        BCOVBasicSessionProviderOptions *bspOptions = [BCOVBasicSessionProviderOptions new];
        bspOptions.sourceSelectionPolicy = [BCOVBasicSourceSelectionPolicy sourceSelectionHLSWithScheme:BCOVSource.URLSchemeHTTPS];
        id<BCOVPlaybackSessionProvider> bsp = [sdkManager createBasicSessionProviderWithOptions:bspOptions];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                               authorizationProxy:authProxy
                                                                                          upstreamSessionProvider:bsp];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:fps
                                                                                                   viewStrategy:nil];

        playbackController.delegate = self;

        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        playbackController.allowsBackgroundAudioPlayback = YES;
        playbackController.allowsExternalPlayback = YES;

        [playbackController addSessionConsumer:self.controlsViewController];
        self.controlsViewController.playbackController = playbackController;

        playbackController;
    });

    self.videoView = ({
        UIView *videoView = [UIView new];
        videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        videoView;
    });

    self.fullscreenViewController = [UIViewController new];

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
    [self.videoContainerView addSubview:self.videoView];

    // Setup the standard view constraints
    // and activate them
    self.videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:self.standardVideoViewConstraints];

    [self requestContentFromPlaybackService];
}

- (NSArray<NSLayoutConstraint *> *)standardVideoViewConstraints
{
    return @[
        [self.videoView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
        [self.videoView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
        [self.videoView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
        [self.videoView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
    ];
}

- (NSArray<NSLayoutConstraint *> *)fullscreenVideoViewConstraints
{
    UIEdgeInsets insets = self.view.safeAreaInsets;
    return @[
        [self.videoView.topAnchor constraintEqualToAnchor:self.fullscreenViewController.view.topAnchor
                                                 constant:insets.top],
        [self.videoView.rightAnchor constraintEqualToAnchor:self.fullscreenViewController.view.rightAnchor],
        [self.videoView.leftAnchor constraintEqualToAnchor:self.fullscreenViewController.view.leftAnchor],
        [self.videoView.bottomAnchor constraintEqualToAnchor:self.fullscreenViewController.view.bottomAnchor
                                                    constant:-insets.bottom]
    ];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId };
    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:nil
                                          completion:^(BCOVVideo *video,
                                                       NSDictionary *jsonResponse,
                                                       NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (video)
        {
#if TARGET_OS_SIMULATOR
            if (video.usesFairPlay)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FairPlay Warning"
                                                                               message:@"FairPlay only works on actual iOS or tvOS devices.\n\nYou will not be able to view any FairPlay content in the iOS or tvOS simulator."
                                                                        preferredStyle:UIAlertControllerStyleAlert];

                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                });

                return;
            }
#endif

            [strongSelf.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }

    }];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
  didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[@"error"];
        // Report any errors that may have occurred with playback.
        NSLog(@"ViewController - Playback error: %@", error.localizedDescription);
    }
}


#pragma mark - ControlsViewControllerFullScreenDelegate

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
        [self.videoContainerView addSubview:self.videoView];
        [NSLayoutConstraint deactivateConstraints:self.fullscreenVideoViewConstraints];
        [NSLayoutConstraint activateConstraints:self.standardVideoViewConstraints];
        [self.controlsViewController didMoveToParentViewController:self];
    }];
}

@end
