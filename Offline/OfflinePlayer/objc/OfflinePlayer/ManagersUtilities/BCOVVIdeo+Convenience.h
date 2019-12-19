//
//  BCOVVIdeo+Convenience.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/30/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

@import BrightcovePlayerSDK;

NS_ASSUME_NONNULL_BEGIN

@interface BCOVVideo (Convenience)

- (BOOL)videoMatchesVideo:(BCOVVideo *)video;

@end

NS_ASSUME_NONNULL_END
