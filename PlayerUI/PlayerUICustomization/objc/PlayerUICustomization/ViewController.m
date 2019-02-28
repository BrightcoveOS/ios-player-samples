//
//  ViewController.m
//  PlayerUICustomization
//
//  Created by Steve Bushell on 6/26/16.
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
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


@import BrightcovePlayerSDK;

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVPUIButtonAccessibilityDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic) id<BCOVPlaybackController> playbackController;
@property (nonatomic) IBOutlet UIView *videoView;
@property (nonatomic) IBOutlet UILabel *layoutLabel;
@property (nonatomic) IBOutlet UIButton *nextLayoutButton;

// Which layout are we displaying?
@property (nonatomic) int layoutIndex;
// This stores a ref to a view we want to show/hide on demand.
@property (nonatomic) BCOVPUILayoutView *hideableLayoutView;

// PlayerUI's Player View
@property (nonatomic) BCOVPUIPlayerView *playerView;

@end

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>
@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        NSLog(@"Setting up Playback Controller");
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        _playbackController = [manager createPlaybackController];
        _playbackController.delegate = self;
        _playbackController.autoAdvance = YES;
        _playbackController.autoPlay = YES;

        // Initialize playback service for retrieving videos
        _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSLog(@"Configure the Player View");

    // Create and set options.
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;

    // Make the controls linger on screen for a long time
    // so you can examine the controls.
    options.hideControlsInterval = 120.0f;

    // But hide and show quickly.
    options.hideControlsAnimationDuration = 0.2f;

    // Create and configure Control View.
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:controlView];
    self.playerView.playbackController = self.playbackController;
    self.playerView.delegate = self;

    // Add BCOVPUIPlayerView to video view.
    [self.videoView addSubview:self.playerView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playerView.topAnchor constraintEqualToAnchor:self.videoView.topAnchor],
                                              [self.playerView.rightAnchor constraintEqualToAnchor:self.videoView.rightAnchor],
                                              [self.playerView.leftAnchor constraintEqualToAnchor:self.videoView.leftAnchor],
                                              [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoView.bottomAnchor],
                                              ]];

    NSLog(@"Request Content from the Video Cloud");
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID
                                    parameters:nil completion:^(BCOVVideo *video,
                                                                NSDictionary *jsonResponse,
                                                                NSError *error)
    {
        if (video)
        {
            [self.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }

     }];
    
    [self accessibilitySetup];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    // When the playlist completes, play it again.
    [self.playbackController setVideos:playlist];
}

- (IBAction)setNextLayout:(id)sender
{
    // Cycle through the various layouts.
    self.layoutIndex ++;

    NSLog(@"Setting layout number %d", self.layoutIndex);

    BCOVPUIControlLayout *newControlLayout;

    switch (self.layoutIndex)
    {
        case 0:
        {
            // Controls for basic VOD
            newControlLayout = [BCOVPUIControlLayout basicVODControlLayout];
            self.layoutLabel.text = @"Built-in VOD Controls";
            self.playerView.controlsView.layout = newControlLayout;
            break;
        }

        case 1:
        {
            // Simple custom layout
            newControlLayout = [self simpleCustomLayout];
            self.layoutLabel.text = @"Simple Custom Controls";
            self.playerView.controlsView.layout = newControlLayout;
            break;
        }

        case 3:
        {
            // Layout for live stream with DVR controls
            newControlLayout = [BCOVPUIControlLayout basicLiveDVRControlLayout];
            self.layoutLabel.text = @"Built-in Live DVR Controls";
            self.playerView.controlsView.layout = newControlLayout;
            break;
        }

        case 2:
        {
            // Layout for live stream
            newControlLayout = [BCOVPUIControlLayout basicLiveControlLayout];
            self.layoutLabel.text = @"Built-in Live Controls";
            self.playerView.controlsView.layout = newControlLayout;
            break;
        }

        case 4:
        {
            // Complex custom layout
            newControlLayout = [self complexCustomLayout];
            self.layoutLabel.text = @"Complex Layout";
            self.playerView.controlsView.layout = newControlLayout;

            // Change font and color on Current Time, Duration, and Separator labels.
            UIFont* font = [UIFont fontWithName:@"Courier" size:18];

            self.playerView.controlsView.currentTimeLabel.font = font;
            self.playerView.controlsView.currentTimeLabel.textColor = [UIColor orangeColor];
            self.playerView.controlsView.durationLabel.font = font;
            self.playerView.controlsView.durationLabel.textColor = [UIColor orangeColor];
            self.playerView.controlsView.timeSeparatorLabel.font = font;
            self.playerView.controlsView.timeSeparatorLabel.textColor = [UIColor greenColor];

            BCOVPUIButton *b = self.playerView.controlsView.screenModeButton;

            // Change color of full-screen button.
            [b setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
            [b setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];

            // Change color of jump back button.
            b = self.playerView.controlsView.jumpBackButton;
            [b setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
            [b setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];

            // Change color of play/pause button.
            b = self.playerView.controlsView.playbackButton;
            [b setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
            [b setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];

            // Customize the slider.
            BCOVPUISlider *slider = self.playerView.controlsView.progressSlider;

            // Custom slider colors
            [slider setBufferProgressTintColor:[UIColor greenColor]];
            [slider setMinimumTrackTintColor:[UIColor orangeColor]];
            [slider setMaximumTrackTintColor:[UIColor purpleColor]];
            [slider setThumbTintColor:[UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:0.5]];

            // Add markers to the slider for your own use
            [slider setMarkerTickColor:[UIColor lightGrayColor]];
            [slider addMarkerAt:30 duration:0.0 isAd:NO image:nil];
            [slider addMarkerAt:60 duration:0.0 isAd:NO image:nil];
            [slider addMarkerAt:90 duration:0.0 isAd:NO image:nil];

            break;
        }

        default:
        {
            // Set nil to remove all controls.
            newControlLayout = nil;
            self.layoutLabel.text = @"Nil layout";
            self.playerView.controlsView.layout = newControlLayout;

            // Reset index
            self.layoutIndex = -1;
            break;
        }
    }
}

- (BCOVPUIControlLayout *)simpleCustomLayout
{
    BCOVPUIControlLayout *layout;

    // Create a new control for each tag.
    // Controls are packaged inside a layout view.
    BCOVPUILayoutView *playbackLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonPlayback width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *currentTimeLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelCurrentTime width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *durationLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelDuration width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *progressLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagSliderProgress width:kBCOVPUILayoutUseDefaultValue elasticity:1.0];
    BCOVPUILayoutView *spacerLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:8 elasticity:1.0];

    // Configure the standard layout lines.
    NSArray *standardLayoutLine1 = @[ spacerLayoutView,
                                      playbackLayoutView,
                                      currentTimeLayoutView,
                                      progressLayoutView,
                                      durationLayoutView,
                                      spacerLayoutView ];

    NSArray *standardLayoutLines = @[ standardLayoutLine1 ];

    // Configure the compact layout lines.
    NSArray *compactLayoutLine1 = @[ progressLayoutView ];
    NSArray *compactLayoutLine2 = @[ spacerLayoutView,
                                     currentTimeLayoutView,
                                     spacerLayoutView,
                                     playbackLayoutView,
                                     spacerLayoutView,
                                     durationLayoutView,
                                     spacerLayoutView ];

    NSArray *compactLayoutLines = @[ compactLayoutLine1, compactLayoutLine2 ];

    // Put the two layout lines into a single control layout object.
    layout = [[BCOVPUIControlLayout alloc] initWithStandardControls:standardLayoutLines
                                                    compactControls:compactLayoutLines];

    // Put the threshold between the width and height to make sure we change layouts on rotation.
    layout.compactLayoutMaximumWidth = (self.view.frame.size.width + self.view.frame.size.height) / 2.0f;

    // Remember the layout view that we want to show/hide.
    self.hideableLayoutView = playbackLayoutView;

    return layout;
}

- (BCOVPUIControlLayout *)complexCustomLayout
{
    BCOVPUIControlLayout *layout;

    // Create a new control for each tag.
    // Controls are packaged inside a layout view.
    BCOVPUILayoutView *playbackLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonPlayback width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *jumpBackButtonLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonJumpBack width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *currentTimeLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelCurrentTime width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *timeSeparatorLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelTimeSeparator width:12 elasticity:0.0]; // don't use default value because we're going to use a monospace font
    BCOVPUILayoutView *durationLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelDuration width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *progressLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagSliderProgress width:kBCOVPUILayoutUseDefaultValue elasticity:1.0];
    BCOVPUILayoutView *closedCaptionLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonClosedCaption width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    closedCaptionLayoutView.removed = YES; // Hide until it's explicitly needed.
    BCOVPUILayoutView *screenModeLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonScreenMode width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    BCOVPUILayoutView *externalRouteLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewExternalRoute width:kBCOVPUILayoutUseDefaultValue elasticity:0.0];
    externalRouteLayoutView.removed = YES; // Hide until it's explicitly needed.
    BCOVPUILayoutView *spacerLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:8 elasticity:1.0];
    BCOVPUILayoutView *standardLogoLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:480 elasticity:0.25];
    BCOVPUILayoutView *compactLogoLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:36 elasticity:0.1];
    BCOVPUILayoutView *buttonLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:80 elasticity:0.2];
    BCOVPUILayoutView *labelLayoutView = [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty width:80 elasticity:0.2];

    // Put UIImages inside our logo layout views.
    {
        // Create logo image inside an image view for display in control bar.
        UIImageView *standardLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bcov_logo_horizontal_white.png"]];
        standardLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        standardLogoImageView.contentMode = UIViewContentModeScaleAspectFill;
        standardLogoImageView.frame = standardLogoLayoutView.frame;

        // Add image view to our empty layout view.
        [standardLogoLayoutView addSubview:standardLogoImageView];
    }

    {
        // Create logo image inside an image view for display in control bar.
        UIImageView *compactLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bcov.png"]];
        compactLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        compactLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
        compactLogoImageView.frame = compactLogoLayoutView.frame;

        // Add image view to our empty layout view.
        [compactLogoLayoutView addSubview:compactLogoImageView];
    }

    {
        // Add UIButton to layout.
        UIButton *button = [[UIButton alloc] initWithFrame:buttonLayoutView.frame];

        [button setTitle:@"Tap Me" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [buttonLayoutView addSubview:button];
    }

    {
        // Add UILabel to layout.
        UILabel *label = [[UILabel alloc] initWithFrame:buttonLayoutView.frame];

        label.text = @"Label";
        label.textColor = [UIColor greenColor];
        label.textAlignment = NSTextAlignmentRight;
        [labelLayoutView addSubview:label];
    }

    // Configure the standard layout lines.
    NSArray *standardLayoutLine1 = @[ playbackLayoutView,
                                      spacerLayoutView,
                                      spacerLayoutView,
                                      currentTimeLayoutView,
                                      progressLayoutView,
                                      durationLayoutView ];

    NSArray *standardLayoutLine2 = @[ buttonLayoutView,
                                      spacerLayoutView,
                                      standardLogoLayoutView,
                                      spacerLayoutView,
                                      labelLayoutView ];

    NSArray *standardLayoutLine3 = @[ jumpBackButtonLayoutView,
                                      spacerLayoutView,
                                      screenModeLayoutView ];

    NSArray *standardLayoutLines = @[ standardLayoutLine1,
                                      standardLayoutLine2,
                                      standardLayoutLine3 ];

    // Configure the compact layout lines.
    NSArray *compactLayoutLine1 = @[ playbackLayoutView,
                                     jumpBackButtonLayoutView,
                                     currentTimeLayoutView,
                                     timeSeparatorLayoutView,
                                     durationLayoutView,
                                     progressLayoutView,
                                     closedCaptionLayoutView,
                                     screenModeLayoutView,
                                     externalRouteLayoutView,
                                     compactLogoLayoutView];

    NSArray *compactLayoutLines = @[ compactLayoutLine1 ];

    layout = [[BCOVPUIControlLayout alloc] initWithStandardControls:standardLayoutLines
                                                    compactControls:compactLayoutLines];

    // Put the threshold between the width and height to make sure we change layouts on rotation.
    layout.compactLayoutMaximumWidth = (self.view.frame.size.width + self.view.frame.size.height) / 2.0f;

    // Remember the layout view that we want to hide.
    self.hideableLayoutView = playbackLayoutView;

    return layout;
}

- (void)handleButtonTap:(UIButton *)button
{
    // When the "Tap Me" button is tapped, show a red label that fades quickly.
    UILabel *label = [[UILabel alloc] initWithFrame:self.playerView.frame];
    label.text = @"Tapped!";
    label.textColor = [UIColor redColor];
    label.font = [UIFont boldSystemFontOfSize:128];
    [label sizeToFit];
    [self.playerView addSubview:label];
    label.center = self.playerView.center;

    [UIView animateWithDuration:1.0f animations:^{

        label.alpha = 0.0;

    } completion:^(BOOL finished) {

        [label removeFromSuperview];

    }];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // When the device is shaken, toggle the removal of the saved layout view.
    NSLog(@"motionBegan - hiding/showing layout view");

    BOOL removed = self.hideableLayoutView.isRemoved;

    self.hideableLayoutView.removed = !removed;

    [self.playerView.controlsView setNeedsLayout];
}

- (void)accessibilitySetup
{
    [self.playerView.controlsView setButtonsAccessibilityDelegate:self];
    
    self.playerView.controlsView.durationLabel.accessibilityLabelPrefix = @"Total Time";
    self.playerView.controlsView.currentTimeLabel.accessibilityLabelPrefix = @"As of now";
    self.playerView.controlsView.progressSlider.accessibilityLabel = @"Timeline";
    self.playbackController.view.accessibilityHint = @"Double tap to show or hide controls";
}

#pragma mark - BCOVPUIButtonAccessibilityDelegate

- (NSString *)accessibilityLabelForButton:(BCOVPUIButton *)button isPrimaryState:(BOOL)isPrimaryState
{
    switch (button.tag)
    {
        case BCOVPUIViewTagButtonPlayback:
            return isPrimaryState ? NSLocalizedString(@"Start Playback", nil) : NSLocalizedString(@"Stop PLayback", nil);
        case BCOVPUIViewTagButtonScreenMode:
            return isPrimaryState ? NSLocalizedString(@"Enter Fullscreen", nil) : NSLocalizedString(@"Exit Fullscreen", nil);
        case BCOVPUIViewTagButtonJumpBack:
            return nil;
        case BCOVPUIViewTagButtonClosedCaption:
            return nil;
        case BCOVPUIViewTagButtonVideo360:
            return nil;
        case BCOVPUIViewTagButtonPreferredBitrate:
            return nil;
        default:
            return nil;
    }
}

@end
