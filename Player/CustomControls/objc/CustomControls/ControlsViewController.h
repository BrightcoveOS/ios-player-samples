//
//  ControlsViewController.h
//  CustomControls
//
//  Created by Michael Moscardini on 10/30/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
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
