//
//  BCOVOfflineVideoStatus+OfflinePlayer.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@interface BCOVOfflineVideoStatus (OfflinePlayer)

@property (nonatomic, readonly, strong) BCOVVideo *offlineVideo;
@property (nonatomic, readonly, strong) NSString *infoForDonwloadState;

@end
