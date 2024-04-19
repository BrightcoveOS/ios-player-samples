//
//  ViewController.m
//  PlayerUICustomization
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

// This sample app shows you how to use the PlayerUI control customization.
// The PlayerUI code is now integrated in the BrightcovePlayerSDK module, so you
// can begin using it without importing any other modules besides the BrightcovePlayerSDK.
//
// There are five sample layouts. When you run the app, you can dynamically
// switch between all the layouts to see them in action.
//
// 1 - Built-in VOD Controls
// This is a Brightcove-supplied built-in layout for displaying normal controls
// with regular video on demand.
// AirPlay and Subtitle/Audio Track controls are included, but only visible
// when they are needed.
//
// 2 - Simple Custom Controls
// This is a simple control layout with only four elements.
// The layout switches from one line to two lines when moving from landscape
// to portrait orientation.
// The code for setting up this layout manually is shown.
//
// 3 - Built-in Live Controls
// This is a Brightcove-supplied built-in layout for displaying normal controls
// with a live video stream.
// AirPlay and Subtitle/Audio Track controls are included, but only visible
// when they are needed.
//
// 4 - Built-in Live DVR Controls
// This is a Brightcove-supplied built-in layout for displaying normal controls
// with a live DVR video stream.
// The Live indicator turns green when you are watching the live edge
// of the video stream. It can be tapped at any time to view the most recent
// part of the video feed.
// AirPlay and Subtitle/Audio Track controls are included, but only visible
// when they are needed.
//
// 5 - Complex Layout
// This is a highly customized layout showing many of the features of
// PlayerUI customization.
// This layout has more items than most, and is designed for iPads.
// For iPhones, a similar layout should be split into shorter rows in portrait
// orientation.
// The code for setting up this layout manually is shown.
// Features include:
//   - Custom colors for text and sliders
//   - Custom font for text labels
//   - Single line of controls in portrait orientation; three lines of controls
//     in landscape orientation
//   - UIImage-based logos added to different layout views
//   - Custom label added to a view
//   - Custom control (with action) added to a control
//   - UIImage view overlapping multiple rows
//   - Layout views using custom elasticities
//   - The play/pause button can be hidden/shown by shaking the device
//     (see motionBegan:withEvent:)
//   - User markers are set on the slider
// AirPlay and Subtitle/Audio Track controls are included, but only visible
//
// 6 - Nil Controls
// You can set the controls layout to nil; this essentially removes
// all playback controls.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "ControlViewStyles.h"
#import "CustomLayouts.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"5702148954001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVPUIButtonAccessibilityDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UILabel *layoutLabel;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, assign) int layoutIndex;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
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

        // Make the controls linger on screen for a long time
        // so you can examine the controls.
        options.hideControlsInterval = 120.0f;

        // But hide and show quickly.
        options.hideControlsAnimationDuration = 0.2f;

        BCOVPUIBasicControlView *controlsView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:controlsView];

        playerView.delegate = self;

        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];

        if (playerView.controlsView)
        {
            playerView.controlsView.durationLabel.accessibilityLabelPrefix = @"Total Time";
            playerView.controlsView.currentTimeLabel.accessibilityLabelPrefix = @"As of now";
            playerView.controlsView.progressSlider.accessibilityLabel = @"Timeline";

            [playerView.controlsView setButtonsAccessibilityDelegate:self];
        }

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

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [super motionEnded:motion withEvent:event];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.tag == %@", @(BCOVPUIViewTagButtonPlayback)];
    BCOVPUILayoutView *hideableLayoutView = [self.playerView.controlsView.layout.allLayoutItems.allObjects filteredArrayUsingPredicate:predicate].firstObject;

    if (hideableLayoutView)
    {
        // When the device is shaken, toggle the removal of the saved layout view.
        NSLog(@"motionBegan - hiding/showing layout view");

        hideableLayoutView.removed = !hideableLayoutView.isRemoved;

        [self.playerView.controlsView setNeedsLayout];
    }
}

- (void)handleButtonTap
{
    // When the "Tap Me" button is tapped, show a red label that fades quickly.
    UILabel *label = [[UILabel alloc] initWithFrame:self.playerView.contentOverlayView.frame];
    label.text = @"Tapped!";
    label.textColor = UIColor.redColor;
    label.font = [UIFont boldSystemFontOfSize:128];
    [label sizeToFit];
    [self.playerView.contentOverlayView addSubview:label];
    label.center = self.playerView.contentOverlayView.center;
    [UIView animateWithDuration:1.0f animations:^{
        label.alpha = 0.0;
    } completion:^(BOOL finished) {
        [label removeFromSuperview];
    }];
}

- (IBAction)setNextLayout
{
    // Cycle through the various layouts.
    self.layoutIndex++;

    CGFloat compactLayoutMaximumWidth = (self.view.frame.size.height + self.view.frame.size.width) / 2;
    BCOVPUIControlLayout *controlLayout;

    switch (self.layoutIndex)
    {
        case 0:
        {
            // Controls for basic VOD
            self.layoutLabel.text = @"Built-in VOD Controls";
            controlLayout = [BCOVPUIControlLayout basicVODControlLayout];
            controlLayout.compactLayoutMaximumWidth = compactLayoutMaximumWidth;
            self.playerView.controlsView.layout = controlLayout;
            break;
        }
        case 1:
        {
            // Simple custom layout
            self.layoutLabel.text = @"Simple Custom Controls";
            controlLayout = [CustomLayouts simpleCustomLayout];
            controlLayout.compactLayoutMaximumWidth = compactLayoutMaximumWidth;
            self.playerView.controlsView.layout = controlLayout;
            [ControlViewStyles simpleForControlsView:self.playerView.controlsView];
            break;
        }
        case 2:
        {
            // Layout for live stream
            self.layoutLabel.text = @"Built-in Live Controls";
            controlLayout = [BCOVPUIControlLayout basicLiveControlLayout];
            controlLayout.compactLayoutMaximumWidth = compactLayoutMaximumWidth;
            self.playerView.controlsView.layout = controlLayout;
            break;
        }
        case 3:
        {
            // Layout for live stream with DVR controls
            self.layoutLabel.text = @"Built-in Live DVR Controls";
            controlLayout = [BCOVPUIControlLayout basicLiveDVRControlLayout];
            controlLayout.compactLayoutMaximumWidth = compactLayoutMaximumWidth;
            self.playerView.controlsView.layout = controlLayout;
            break;
        }
        case 4:
        {
            self.layoutLabel.text = @"Complex Layout";
            controlLayout = [CustomLayouts complexCustomLayout];
            controlLayout.compactLayoutMaximumWidth = compactLayoutMaximumWidth;
            self.playerView.controlsView.layout = controlLayout;
            [ControlViewStyles complexForControlsView:self.playerView.controlsView];
            break;
        }

        default:
        {
            // Set nil to remove all controls.
            self.layoutLabel.text = @"nil layout";
            self.playerView.controlsView.layout = nil;

            // Reset index
            self.layoutIndex = -1;
            break;
        }
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
            strongSelf.layoutIndex = -1;
            [strongSelf setNextLayout];
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
       didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    // When the playlist completes, play it again.
    [self.playbackController setVideos:playlist];
}


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}


#pragma mark - BCOVPUIButtonAccessibilityDelegate

- (NSString *)accessibilityLabelForButton:(BCOVPUIButton *)button
                           isPrimaryState:(BOOL)isPrimaryState
{
    switch (button.tag)
    {
        case BCOVPUIViewTagButtonPlayback:
            return (isPrimaryState ?
                    NSLocalizedString(@"Start Playback", "") :
                    NSLocalizedString(@"Stop Playback", ""));

        case BCOVPUIViewTagButtonScreenMode:
            return (isPrimaryState ?
                    NSLocalizedString(@"Enter Fullscreen", "") :
                    NSLocalizedString(@"Exit Fullscreen", ""));

        case BCOVPUIViewTagButtonJumpBack:
        case BCOVPUIViewTagButtonClosedCaption:
        case BCOVPUIViewTagButtonVideo360:
        case BCOVPUIViewTagButtonPreferredBitrate:
            return nil;

        default:
            return nil;
    }
}

@end
