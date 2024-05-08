//
//  DownloadManager.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@interface DownloadManager : NSObject <BCOVOfflineVideoManagerDelegate>

+ (instancetype)shared;
+ (NSDictionary *)downloadParameters;
+ (NSDictionary *)licenseParameters;

- (void)doDownloadForVideo:(BCOVVideo *)video;

@end
