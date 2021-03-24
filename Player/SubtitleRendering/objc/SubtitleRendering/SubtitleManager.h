//
//  SubtitleManager.h
//  SubtitleRendering
//
//  Created by Jeremy Blaker on 3/24/21.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubtitleManager : NSObject

- (instancetype)initWithURL:(NSURL *)subtitleURL;
- (NSString *)subtitleForTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
