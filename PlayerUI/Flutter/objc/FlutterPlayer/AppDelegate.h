//
//  AppDelegate.h
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class FlutterEngine, FlutterViewController;


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, readonly, strong) FlutterEngine *flutterEngine;

@property (nonatomic, strong) FlutterViewController *flutterViewController;

@end
