//
//  AppDelegate.h
//  BrightcoveCastReceiver
//
//  Created by Jeremy Blaker on 7/6/20.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCKUICastContainerViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) GCKUICastContainerViewController *castContainerViewController;

@end

