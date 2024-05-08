//
//  BCOVVideo+OfflinePlayer.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@interface BCOVVideo (OfflinePlayer)

@property (nonatomic, readonly, strong) NSString *accountId;
@property (nonatomic, readonly, strong) NSString *videoId;
@property (nonatomic, readonly, strong) NSString *localizedName;
@property (nonatomic, readonly, strong) NSString *localizedShortDescription;
@property (nonatomic, readonly, strong) NSString *duration;
@property (nonatomic, readonly, strong) NSString *offlineVideoToken;
@property (nonatomic, readonly, strong) NSString *license;

- (BOOL)matchesWithVideo:(BCOVVideo *)video;

@end

