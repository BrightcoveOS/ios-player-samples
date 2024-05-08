//
//  UITabBarController+OfflinePlayer.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownloadsViewController;
@class SettingsViewController;
@class VideosViewController;


@interface UIViewController (OfflinePlayer)

@property (nonatomic, readonly, assign) BOOL isVisible;

@end


@interface UITabBarController (OfflinePlayer)

@property (nonatomic, readonly, strong) VideosViewController *videosViewController;
@property (nonatomic, readonly, strong) DownloadsViewController *downloadsViewController;
@property (nonatomic, readonly, strong) SettingsViewController *settingsViewController;

- (void)updateBadge;

@end
