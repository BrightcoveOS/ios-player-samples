//
//  SettingsViewController.h
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;

#import "VideosViewController.h"

@interface SettingsViewController : UIViewController <UITabBarControllerDelegate>

@property (nonatomic, nonnull) UITabBarController *tabBarController;

- (long long int)bitrate;
- (BOOL)purchaseLicenseType;
- (unsigned long long)rentalDuration;

@end

extern SettingsViewController * _Nonnull gSettingsViewController;
