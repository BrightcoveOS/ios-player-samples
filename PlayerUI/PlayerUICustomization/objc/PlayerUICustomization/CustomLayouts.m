//
//  CustomLayouts.m
//  PlayerUICustomization
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "ViewController.h"

#import "CustomLayouts.h"


@implementation CustomLayouts

+ (BCOVPUIControlLayout *)simpleCustomLayout
{
    // Create a new control for each tag.
    // Controls are packaged inside a layout view.
    BCOVPUILayoutView *playbackLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonPlayback
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *closedCaptionView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonClosedCaption
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *currentTimeLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelCurrentTime
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *durationLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelDuration
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *progressLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagSliderProgress
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:1.0];

    BCOVPUILayoutView *spacerLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty
                                                    width:8
                                               elasticity:1.0];

    // Configure the standard layout lines.
    NSArray *standardLayoutLine1 = @[ spacerLayoutView,
                                      playbackLayoutView,
                                      closedCaptionView,
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
                                     closedCaptionView,
                                     spacerLayoutView,
                                     durationLayoutView,
                                     spacerLayoutView ];

    NSArray *compactLayoutLines = @[ compactLayoutLine1, compactLayoutLine2 ];

    // Put the two layout lines into a single control layout object.
    BCOVPUIControlLayout *layout = [[BCOVPUIControlLayout alloc] initWithStandardControls:standardLayoutLines
                                                                          compactControls:compactLayoutLines];

    return layout;
}

+ (BCOVPUIControlLayout *)complexCustomLayout
{
    // Create a new control for each tag.
    // Controls are packaged inside a layout view.

    BCOVPUILayoutView *playbackLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonPlayback
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *jumpBackButtonLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonJumpBack
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *currentTimeLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelCurrentTime
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    // don't use default value because we're going to use a monospace font
    BCOVPUILayoutView *timeSeparatorLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelTimeSeparator
                                                    width:12
                                               elasticity:0.0];

    BCOVPUILayoutView *durationLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagLabelDuration
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *progressLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagSliderProgress
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *closedCaptionLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonClosedCaption
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];
    closedCaptionLayoutView.removed = YES; // Hide until it's explicitly needed.

    BCOVPUILayoutView *screenModeLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagButtonScreenMode
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];

    BCOVPUILayoutView *externalRouteLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewExternalRoute
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:0.0];
    externalRouteLayoutView.removed = YES; // Hide until it's explicitly needed.

    BCOVPUILayoutView *spacerLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty
                                                    width:kBCOVPUILayoutUseDefaultValue
                                               elasticity:1.0];

    BCOVPUILayoutView *standardLogoLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty
                                                    width:480
                                               elasticity:0.25];

    BCOVPUILayoutView *compactLogoLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty
                                                    width:36
                                               elasticity:0.1];

    BCOVPUILayoutView *buttonLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty
                                                    width:80
                                               elasticity:0.2];

    BCOVPUILayoutView *labelLayoutView =
    [BCOVPUIBasicControlView layoutViewWithControlFromTag:BCOVPUIViewTagViewEmpty
                                                    width:80
                                               elasticity:0.2];

    // Put UIImages inside our logo layout views.
    // Create logo image inside an image view for display in control bar.
    UIImage *imageLogo = [UIImage imageNamed:@"BrightcoveLogo"];
    UIImageView *standardLogoImageView = [[UIImageView alloc] initWithImage:imageLogo];
    standardLogoImageView.frame = standardLogoLayoutView.frame;
    standardLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    standardLogoImageView.contentMode = UIViewContentModeScaleAspectFit;

    // Add image view to our empty layout view.
    [standardLogoLayoutView addSubview:standardLogoImageView];

    // Create logo image inside an image view for display in control bar.
    UIImage *appIcon = [UIImage imageNamed:@"AppIcon"];
    UIImageView *compactLogoImageView = [[UIImageView alloc] initWithImage:appIcon];
    compactLogoImageView.frame = compactLogoLayoutView.frame;
    compactLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    compactLogoImageView.contentMode = UIViewContentModeScaleAspectFit;

    // Add image view to our empty layout view.
    [compactLogoLayoutView addSubview:compactLogoImageView];

    // Add UIButton to layout.
    UIButton *button = [[UIButton alloc] initWithFrame:buttonLayoutView.frame];
    [button setTitle:@"Tap Me" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.greenColor forState:UIControlStateNormal];
    [button setTitleColor:UIColor.yellowColor forState:UIControlStateHighlighted];

    ViewController *viewController = (ViewController *)UIApplication.sharedApplication.delegate.window.rootViewController;
    [button addTarget:viewController
               action:@selector(handleButtonTap)
     forControlEvents:UIControlEventTouchUpInside];
    [buttonLayoutView addSubview:button];

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
                                      closedCaptionLayoutView,
                                      screenModeLayoutView ];

    NSArray *standardLayoutLines = @[ standardLayoutLine1,
                                      standardLayoutLine2,
                                      standardLayoutLine3 ];

    // Configure the compact layout lines.
    NSArray *compactLayoutLine1 = @[ playbackLayoutView,
                                     currentTimeLayoutView,
                                     timeSeparatorLayoutView,
                                     durationLayoutView,
                                     progressLayoutView,
                                     spacerLayoutView,
                                     compactLogoLayoutView ];

    NSArray *compactLayoutLines = @[ compactLayoutLine1 ];

    BCOVPUIControlLayout *layout = [[BCOVPUIControlLayout alloc] initWithStandardControls:standardLayoutLines
                                                                          compactControls:compactLayoutLines];
    return layout;
}

@end
