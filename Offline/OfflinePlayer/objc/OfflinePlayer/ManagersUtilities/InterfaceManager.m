//
//  InterfaceManager.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/28/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "InterfaceManager.h"
#import "AppDelegate.h"

typedef NS_ENUM(NSInteger, TabIndex)
{
    TabIndexVideos = 0,
    TabIndexDownloads,
    TabIndexSettings
};

@interface InterfaceManager ()

@property (nonatomic, weak) UITabBarController *tabBarController;

@end

@implementation InterfaceManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static InterfaceManager *interfaceManager;
    dispatch_once(&onceToken, ^{
        interfaceManager = [InterfaceManager new];
    });
    return interfaceManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    UIViewController *rootViewController = ((AppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController;
    if ([rootViewController isKindOfClass:UITabBarController.class])
    {
        self.tabBarController = (UITabBarController *)rootViewController;
    }
}

- (void)updateTabBarDelegate:(id<UITabBarControllerDelegate>)delegate
{
    self.tabBarController.delegate = delegate;
}

- (void)updateDownloadsTabBadgeValue:(NSString *)badgeValue
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tabBarController.tabBar.items[TabIndexDownloads].badgeValue = badgeValue;
    });
}

- (DownloadsViewController *)downloadsViewController
{
    UIViewController *vc = self.tabBarController.viewControllers[TabIndexDownloads];
    return [vc isKindOfClass:NSClassFromString(@"DownloadsViewController")] ? (DownloadsViewController *)vc : nil;
}

- (VideosViewController *)videosViewController
{
    UIViewController *vc = self.tabBarController.viewControllers[TabIndexVideos];
    return [vc isKindOfClass:NSClassFromString(@"VideosViewController")] ? (VideosViewController *)vc : nil;
}

- (SettingsViewController *)settingsViewController
{
    UIViewController *vc = self.tabBarController.viewControllers[TabIndexSettings];
    return [vc isKindOfClass:NSClassFromString(@"SettingsViewController")] ? (SettingsViewController *)vc : nil;
}

@end
