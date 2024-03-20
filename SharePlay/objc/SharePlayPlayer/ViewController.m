//
//  ViewController.m
//  SharePlayPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "SharePlayPlayer-Swift.h"
#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, WatchTogetherWrapperDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIButton *playWithSharePlayButton;
@property (nonatomic, weak) IBOutlet UIButton *playLocallyButton;
@property (nonatomic, weak) IBOutlet UIButton *endSharePlayButton;
@property (nonatomic, weak) IBOutlet UILabel *groupSessionLabel;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVBasicSessionProviderSourceSelectionPolicy sourceSelectionPolicy;
@property (nonatomic, strong) WatchTogetherWrapper *watchTogether;
@property (nonatomic, assign) BOOL playWithSharePlay;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.endSharePlayButton.enabled = NO;

    [self setup];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setup
{
    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        options.presentingViewController = self;
        options.automaticControlTypeSelection = YES;
        options.showPictureInPictureButton = YES;

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:nil];

        playerView.delegate = self;

        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];

        playerView;
    });

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                              authorizationProxy:authProxy
                                                                                         upstreamSessionProvider:nil];

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:fps
                                                         viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    self.watchTogether = ({
        WatchTogetherWrapper *watchTogether = [WatchTogetherWrapper new];
        watchTogether.delegate = self;
        watchTogether.playbackController = self.playbackController;

        [self.playbackController addSessionConsumer:watchTogether];

        watchTogether;
    });

    self.sourceSelectionPolicy = [BCOVBasicSourceSelectionPolicy sourceSelectionHLSWithScheme:kBCOVSourceURLSchemeHTTPS];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId };
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

            if (strongSelf.playWithSharePlay)
            {
                NSLog(@"ViewController - Playing video with SharePlay");
                BCOVSource *source = strongSelf.sourceSelectionPolicy(video);
                [strongSelf.watchTogether activateNewActivityWithVideo:video
                                                            withSource:source];
            }
            else
            {
                NSLog(@"ViewController - Playing video locally");
                [self.playbackController setVideos:@[video]];
            }
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }

    }];
}

- (void)updateSessionLabelWithStatus:(NSString *)status
{
    self.groupSessionLabel.text = [NSString stringWithFormat:@"Group Session: %@", status];
}

#pragma mark IBActions

- (IBAction)playLocallyButtonPressed:(id)sender
{
    // End the existing SharePlay activity if needed
    [self.watchTogether endSharePlay];

    self.playWithSharePlay = NO;
    [self requestContentFromPlaybackService];
}

- (IBAction)playWithSharePlayButtonPressed:(UIButton *)sender
{
    self.playWithSharePlay = YES;
    [self requestContentFromPlaybackService];
}

- (IBAction)endSharePlayButtonPressed:(id)sender
{
    [self.watchTogether endSharePlay];
}


#pragma mark - WatchTogetherWrapperDelegate

- (void)groupSessionWasJoined
{
    NSLog(@"ViewController - Activity was Joined");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSessionLabelWithStatus:@"Joined"];
        self.endSharePlayButton.enabled = YES;
    });
}

- (void)groupSessionWasInvalidated
{
    NSLog(@"ViewController - Activity was Invalidated");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSessionLabelWithStatus:@"Inactive"];
        self.endSharePlayButton.enabled = NO;
    });
}

- (void)activityWasDisabled
{
    NSLog(@"ViewController - Activity was Disabled or No Activity Active");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSessionLabelWithStatus:@"Inactive"];
        self.endSharePlayButton.enabled = NO;
    });
}

- (void)activityWasActivated
{
    NSLog(@"ViewController - Activity did Activate");
}

- (void)activityFailedActivation
{
    NSLog(@"ViewController - Activity Failed to Activate");
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


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

@end
