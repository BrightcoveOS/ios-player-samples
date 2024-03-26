//
//  UIDevice+OfflinePlayer.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCOVVideo;


@interface UIDevice (OfflinePlayer)

@property (nonatomic, readonly, strong) NSString *freeDiskSpace;
@property (nonatomic, readonly, strong) NSString *totalDiskSpace;

- (NSString *)usedDiskSpaceWithUnitsForVideo:(BCOVVideo *)video;

- (double)usedDiskSpaceForVideo:(BCOVVideo *)video;

@end
