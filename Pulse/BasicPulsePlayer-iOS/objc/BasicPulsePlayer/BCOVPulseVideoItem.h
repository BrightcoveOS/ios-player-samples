//
//  BCOVPulseVideoItem.h
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BCOVPulseVideoItem : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *category;
@property (nonatomic) NSArray<NSString *> *tags;
@property (nonatomic) NSArray<NSNumber *> *midrollPositions;
@property (nonatomic) BOOL extendSession;

+ (BCOVPulseVideoItem *)initWithDictionary:(NSDictionary *)dictionary;

@end
