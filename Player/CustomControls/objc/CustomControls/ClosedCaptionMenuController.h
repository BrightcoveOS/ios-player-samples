//
//  ClosedCaptionMenuController.h
//  CustomControls
//
//  Created by Jeremy Blaker on 2/26/21.
//  Copyright © 2021 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BCOVPlaybackSession;
@class ControlsViewController;

NS_ASSUME_NONNULL_BEGIN

@interface ClosedCaptionMenuController : UITableViewController

@property (nonatomic, weak) ControlsViewController *controlsView;
@property (nonatomic, weak) id<BCOVPlaybackSession> currentSession;

@end

NS_ASSUME_NONNULL_END
