//
//  SubtitleManager.h
//  SubtitleRendering
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>


@interface SubtitleManager : NSObject

- (instancetype)initWithURL:(NSURL *)subtitleURL;
- (NSString *)subtitleForTime:(CMTime)time;

@end
