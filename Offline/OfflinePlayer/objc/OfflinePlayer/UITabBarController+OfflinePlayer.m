//
//  UITabBarController+OfflinePlayer.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "DownloadsViewController.h"
#import "SettingsViewController.h"
#import "VideosViewController.h"

#import "UITabBarController+OfflinePlayer.h"


typedef NS_ENUM(NSInteger, TabIndex)
{
    TabIndexVideos = 0,
    TabIndexDownloads,
    TabIndexSettings
};


@implementation UIViewController (OfflinePlayer)

- (BOOL)isVisible
{
    return self.isViewLoaded && self.view.window;
}

@end


@implementation UITabBarController (OfflinePlayer)

- (VideosViewController *)videosViewController
{
    return self.viewControllers[TabIndexVideos];
}

- (DownloadsViewController *)downloadsViewController
{
    return self.viewControllers[TabIndexDownloads];
}

- (SettingsViewController *)settingsViewController
{
    return self.viewControllers[TabIndexSettings];
}

- (void)updateBadge
{
    BCOVOfflineVideoManager *offlineManager = BCOVOfflineVideoManager.sharedManager;
    NSArray *offlineVideoStatusArray = [offlineManager offlineVideoStatus];

    NSPredicate *predicate =
    [NSPredicate predicateWithFormat:@"self.downloadState == %@", @(BCOVOfflineVideoDownloadStateDownloading)];
    NSUInteger filteredCount = [offlineVideoStatusArray filteredArrayUsingPredicate:predicate].count;
    self.downloadsViewController.tabBarItem.badgeValue = (filteredCount > 0 ?
                                                          [NSString stringWithFormat:@"%li", filteredCount] :
                                                          nil);
}

@end
