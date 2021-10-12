//
//  ControlsViewController.h
//  CustomControls
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;

@protocol ControlsViewControllerFullScreenDelegate <NSObject>

- (void)handleEnterFullScreenButtonPressed;
- (void)handleExitFullScreenButtonPressed;

@end


@interface ControlsViewController : UIViewController <BCOVPlaybackSessionConsumer, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<ControlsViewControllerFullScreenDelegate> delegate;
@property (nonatomic, assign) BOOL closedCaptionEnabled;
@property (nonatomic, weak) id<BCOVPlaybackController> playbackController;

@end
