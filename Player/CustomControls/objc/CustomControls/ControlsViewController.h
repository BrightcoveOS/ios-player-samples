//
//  ControlsViewController.h
//  CustomControls
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;

@protocol ControlsViewControllerFullScreenDelegate <NSObject>

- (void)handleEnterFullScreenButtonPressed;
- (void)handleExitFullScreenButtonPressed;

@end


@interface ControlsViewController : UIViewController <BCOVPlaybackSessionConsumer, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<ControlsViewControllerFullScreenDelegate> delegate;

@end
