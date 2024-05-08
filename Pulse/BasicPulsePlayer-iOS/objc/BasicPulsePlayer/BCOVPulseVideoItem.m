//
//  BCOVPulseVideoItem.m
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "BCOVPulseVideoItem.h"


@implementation BCOVPulseVideoItem

+ (BCOVPulseVideoItem *)initWithDictionary:(NSDictionary *)dictionary
{
    BCOVPulseVideoItem *videoItem = [BCOVPulseVideoItem new];

    videoItem.title            = dictionary[@"content-title"];
    videoItem.category         = dictionary[@"category"];
    videoItem.tags             = dictionary[@"tags"];
    videoItem.midrollPositions = dictionary[@"midroll-positions"];
    videoItem.extendSession    = dictionary[@"extend-session"];

    return videoItem;
}

@end
