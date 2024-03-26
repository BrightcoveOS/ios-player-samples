//
//  SettingsViewController.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsViewController : UIViewController

@property (nonatomic, readonly, assign) BOOL allowDownloadsOverCellular;
@property (nonatomic, readonly, assign) BOOL purchaseLicenseType;

@property (nonatomic, readonly, assign) UInt64 bitrate;
@property (nonatomic, readonly, assign) UInt64 rentalDuration;
@property (nonatomic, readonly, assign) UInt64 playDuration;

@end
