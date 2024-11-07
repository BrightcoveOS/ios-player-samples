//
//  ViewController.m
//  Video360Player
//
//  Created by Steve Bushell on 12/22/16.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve and play a 360 video.
 * The code for retrieving and playing the video is identical
 * to any other code that retrieves and plays a video from Video Cloud.
 *
 * What makes this code different is the usage of the
 * BCOVPUIPlayerViewDelegate delegate method
 * `-didSetVideo360NavigationMethod:projectionStyle:`
 * This method is called when the Video 360 button is tapped, and indicates that
 * you probably want to set the device orientation to landscape if the
 * projection method has changed to VR Goggles mode.
 *
 * The code below shows how to handle changing the device orientation
 * when that delegate is called.
 */

@import BrightcovePlayerSDK;

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"1685628526640737870";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) NSObject<BCOVPlaybackController> *playbackController;

@property (nonatomic, assign) BOOL landscapeOnly;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return (self.landscapeOnly
            ? UIInterfaceOrientationMaskLandscape
            : UIInterfaceOrientationMaskAll);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

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

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    [self requestContentFromPlaybackService];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
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

            // Check "projection" property to confirm that this is a 360 degree video
            NSString *projectionProperty = video.properties[BCOVVideo.PropertyKeyProjection];

            if ([projectionProperty isEqualToString:@"equirectangular"])
            {
                NSLog(@"Retrieved a 360 video");
            }

            [strongSelf.playbackController setVideos:@[video]];
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


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

- (void)didSetVideo360NavigationMethod:(BCOVPUIVideo360NavigationMethod)navigationMethod
                       projectionStyle:(BCOVVideo360ProjectionStyle)projectionStyle
{
    // This method is called when the Video 360 button is tapped.
    // Use this notification to force an orientation change for the VR Goggles projection style.
    switch (projectionStyle)
    {
        case BCOVVideo360ProjectionStyleNormal:
        {
            NSLog(@"projectionStyle == BCOVVideo360ProjectionStyleNormal");

            // No landscape restriction
            self.landscapeOnly = NO;

            // If the goggles are off, change the device orientation
            // and exit full-screen

            [UIDevice.currentDevice setValue:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]
                                      forKey:@"orientation"];
            [UIViewController attemptRotationToDeviceOrientation];
            [self.playerView performScreenTransitionWithScreenMode:BCOVPUIScreenModeNormal];
            break;
        }

        case BCOVVideo360ProjectionStyleVRGoggles:
        {
            NSLog(@"projectionStyle == BCOVVideo360ProjectionStyleVRGoggles");

            // Allow only landscape if wearing goggles
            self.landscapeOnly = YES;

            // If the goggles are on, change the device orientation
            switch (UIDevice.currentDevice.orientation)
            {
                case UIDeviceOrientationLandscapeLeft:
                case UIDeviceOrientationLandscapeRight:
                    // already landscape
                    break;

                default:
                {
                    // switch orientation
                    [UIDevice.currentDevice setValue:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft]
                                              forKey:@"orientation"];
                    [UIViewController attemptRotationToDeviceOrientation];
                    break;
                }
            }
        }
    }
}

@end
