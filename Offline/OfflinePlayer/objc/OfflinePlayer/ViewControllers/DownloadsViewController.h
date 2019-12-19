//
//  DownloadsViewController.h
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadsViewController : UIViewController <UITabBarControllerDelegate>

- (void)refresh;
- (void)updateInfoForSelectedDownload;

// Set a number on the "Downloads" tab icon
- (void)updateBadge;

@end
