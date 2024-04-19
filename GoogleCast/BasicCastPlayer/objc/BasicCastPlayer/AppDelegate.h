//
//  AppDelegate.h
//  BasicCastPlayer
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class GCKUICastContainerViewController;


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) GCKUICastContainerViewController *castContainerViewController;

@end
