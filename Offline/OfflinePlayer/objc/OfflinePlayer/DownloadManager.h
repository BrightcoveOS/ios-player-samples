//
//  DownloadManager.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;

#import <UIKit/UIKit.h>

@interface DownloadManager : NSObject <BCOVOfflineVideoManagerDelegate>

+ (instancetype)shared;
+ (NSDictionary *)downloadParameters;
+ (NSDictionary *)licenseParameters;

- (void)doDownloadForVideo:(BCOVVideo *)video;

@end
