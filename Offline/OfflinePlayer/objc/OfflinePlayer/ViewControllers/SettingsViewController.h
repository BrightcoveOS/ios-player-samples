//
//  SettingsViewController.h
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2020 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITabBarControllerDelegate>

- (long long int)bitrate;
- (BOOL)purchaseLicenseType;
- (unsigned long long)rentalDuration;
- (unsigned long long)playDuration;

@end
