//
//  ControlViewStyles.m
//  PlayerUICustomization
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "ControlViewStyles.h"


@implementation ControlViewStyles

+ (void)simpleForControlsView:(BCOVPUIBasicControlView *)controlsView
{
    // Customize the font for the play/pause button
    // This font is registered in Info.plist
    UIFont *fontello = [UIFont fontWithName:@"fontello" size:20];
    BCOVPUIButton *playbackButton = controlsView.playbackButton;
    playbackButton.titleLabel.font = fontello;
    playbackButton.primaryTitle = @"\ue801";
    playbackButton.secondaryTitle = @"\ue802";
    [playbackButton showPrimaryTitle:YES];

    // Alternatively you can customize a single-state button
    // with an image instead
    UIImage *iconImage = [UIImage imageNamed:@"captions.bubble"];
    BCOVPUIButton *ccButton = controlsView.closedCaptionButton;
    ccButton.primaryTitle = @"";
    ccButton.secondaryTitle = @"";
    [ccButton showPrimaryTitle:YES];
    [ccButton setImage:iconImage forState:UIControlStateNormal];
    ccButton.tintColor = UIColor.whiteColor;
    ccButton.backgroundColor = UIColor.clearColor;
}

+ (void)complexForControlsView:(BCOVPUIBasicControlView *)controlsView
{
    UIFont* font = [UIFont fontWithName:@"Courier" size:16];

    controlsView.currentTimeLabel.font = font;
    controlsView.currentTimeLabel.textColor = UIColor.orangeColor;

    controlsView.durationLabel.font = font;
    controlsView.durationLabel.textColor = UIColor.orangeColor;

    controlsView.timeSeparatorLabel.font = font;
    controlsView.timeSeparatorLabel.textColor = UIColor.orangeColor;

    // Change color of play/pause button.
    BCOVPUIButton *playbackButton = controlsView.playbackButton;
    [playbackButton setTitleColor:UIColor.orangeColor forState:UIControlStateNormal];
    [playbackButton setTitleColor:UIColor.yellowColor forState:UIControlStateHighlighted];

    // Change color of jump back button.
    BCOVPUIButton *jumpBackButton = controlsView.jumpBackButton;
    [jumpBackButton setTitleColor:UIColor.orangeColor forState:UIControlStateNormal];
    [jumpBackButton setTitleColor:UIColor.yellowColor forState:UIControlStateHighlighted];

    // Change color of full-screen button.
    BCOVPUIButton *screenModeButton = controlsView.screenModeButton;
    [screenModeButton setTitleColor:UIColor.orangeColor forState:UIControlStateNormal];
    [screenModeButton setTitleColor:UIColor.yellowColor forState:UIControlStateHighlighted];

    // Change color of closed-captions button.
    BCOVPUIButton *closedCaptionButton = controlsView.closedCaptionButton;
    [closedCaptionButton setTitleColor:UIColor.orangeColor forState:UIControlStateNormal];
    [closedCaptionButton setTitleColor:UIColor.yellowColor forState:UIControlStateHighlighted];

    // Customize the slider.
    BCOVPUISlider *slider = controlsView.progressSlider;
    [slider setBufferProgressTintColor:UIColor.greenColor];
    [slider setMinimumTrackTintColor:UIColor.orangeColor];
    [slider setMaximumTrackTintColor:UIColor.purpleColor];
    [slider setThumbTintColor:[UIColor colorWithRed:0.9 green:0.3
                                               blue:0.3 alpha:0.5]];

    // Add markers to the slider for your own use
    [slider setMarkerTickColor:UIColor.lightGrayColor];
    [slider addMarkerAt:30 duration:0.0 isAd:NO image:nil];
    [slider addMarkerAt:60 duration:0.0 isAd:NO image:nil];
    [slider addMarkerAt:90 duration:0.0 isAd:NO image:nil];
}

@end
