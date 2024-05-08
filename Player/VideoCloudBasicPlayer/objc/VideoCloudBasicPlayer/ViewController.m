//
//  ViewController.m
//  VideoCloudBasicPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "NowPlayingHandler.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kAccountId = @"5434391461001";
// Video Asset
static NSString * const kVideoId = @"6140448705001";
// Audio-Only Asset
// static NSString * const kVideoId = @"1732548841120406830";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIButton *muteButton;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) NowPlayingHandler *nowPlayingHandler;
@property (nonatomic, weak) AVPlayer *currentPlayer;

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

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:fps
                                                         viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        playbackController.allowsExternalPlayback = YES;
        playbackController.allowsBackgroundAudioPlayback = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    self.nowPlayingHandler = [[NowPlayingHandler alloc] initWithPlaybackController:self.playbackController];

    [self setUpAudioSession];

    [self requestContentFromPlaybackService];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setUpAudioSession
{
    NSError *categoryError = nil;
    BOOL success;

    // If the player is muted, then allow mixing.
    // Ensure other apps can have their background audio
    // active when this app is in foreground
    if (self.currentPlayer.isMuted)
    {
        success = [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback
                                                 withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                                       error:&categoryError];
    }
    else
    {
        success = [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback
                                                 withOptions:0
                                                       error:&categoryError];
    }

    if (!success)
    {
        NSLog(@"Error setting AVAudioSession category. Because of this, there may be no sound. %@", categoryError);
    }
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

            [strongSelf.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }

    }];
}

- (IBAction)muteButtonPressed:(id)sender
{
    if (!self.currentPlayer)
    {
        return;
    }

    if (self.currentPlayer.isMuted)
    {
        [self.muteButton setTitle:@"Mute AVPlayer"
                         forState:UIControlStateNormal];
    }
    else
    {
        [self.muteButton setTitle:@"Unmute AVPlayer"
                         forState:UIControlStateNormal];
    }

    self.currentPlayer.muted = !self.currentPlayer.isMuted;

    [self setUpAudioSession];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"Advanced to new session.");

    self.currentPlayer = session.player;

    // Enable route detection for AirPlay
    // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
    self.playerView.controlsView.routeDetector.routeDetectionEnabled = YES;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
  didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventEnd isEqualToString:lifecycleEvent.eventType])
    {
        // Disable route detection for AirPlay
        // https://developer.apple.com/documentation/avfoundation/avroutedetector/2915762-routedetectionenabled
        self.playerView.controlsView.routeDetector.routeDetectionEnabled = NO;
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
             didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"Progress: %0.2f seconds", progress);
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
       determinedMediaType:(BCOVSourceMediaType)mediaType
{
    switch (mediaType)
    {
        case BCOVSourceMediaTypeAudio:
            [self.nowPlayingHandler updateNowPlayingInfoForAudioOnly];
            break;
        default:
            break;
    }
}


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

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
