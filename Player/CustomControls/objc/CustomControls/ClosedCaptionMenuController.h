//
//  ClosedCaptionMenuController.h
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@class ControlsViewController;


@interface ClosedCaptionMenuController : UITableViewController

@property (nonatomic, weak) id<BCOVPlaybackSession> currentSession;
@property (nonatomic, weak) ControlsViewController *controlsView;

@end
