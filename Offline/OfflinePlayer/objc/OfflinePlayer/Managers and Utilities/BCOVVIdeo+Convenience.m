//
//  BCOVVIdeo+Convenience.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/30/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "BCOVVIdeo+Convenience.h"

@implementation BCOVVideo (Convenience)

- (BOOL)videoMatchesVideo:(BCOVVideo *)video
{
    // Returns YES if the two video objects reference the same video asset.
    // Specifically, they have the same account and same video Id.
    NSString *v1Account = self.properties[kBCOVVideoPropertyKeyAccountId];
    NSString *v1Id = self.properties[kBCOVVideoPropertyKeyId];
    NSString *v2Account = video.properties[kBCOVVideoPropertyKeyAccountId];
    NSString *v2Id = video.properties[kBCOVVideoPropertyKeyId];

    return ([v1Account isEqualToString:v2Account]
            && [v1Id isEqualToString:v2Id]);
}

@end
