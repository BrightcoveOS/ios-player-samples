//
//  InterfaceManager.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/28/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadsViewController, SettingsViewController, VideosViewController;

NS_ASSUME_NONNULL_BEGIN

@interface InterfaceManager : NSObject

+ (instancetype)sharedInstance;

- (DownloadsViewController * _Nullable)downloadsViewController;
- (SettingsViewController * _Nullable)settingsViewController;
- (VideosViewController * _Nullable)videosViewController;

- (void)updateTabBarDelegate:(id<UITabBarControllerDelegate>)delegate;
- (void)updateDownloadsTabBadgeValue:(NSString * _Nullable)badgeValue;

@end

NS_ASSUME_NONNULL_END
