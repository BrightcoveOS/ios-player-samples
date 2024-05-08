//
//  ControlsViewController.h
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@protocol ControlsViewControllerFullScreenDelegate <NSObject>

- (void)handleEnterFullScreenButtonPressed;
- (void)handleExitFullScreenButtonPressed;

@end


@interface ControlsViewController : UIViewController <BCOVPlaybackSessionConsumer>

@property (nonatomic, weak) id<ControlsViewControllerFullScreenDelegate> delegate;
@property (nonatomic, weak) id<BCOVPlaybackController> playbackController;
@property (nonatomic, assign) BOOL closedCaptionEnabled;

@end
