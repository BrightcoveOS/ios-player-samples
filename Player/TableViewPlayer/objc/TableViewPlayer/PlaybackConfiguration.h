//
//  PlaybackConfiguration.h
//  TableViewPlayer
//
//  Created by Jeremy Blaker on 6/15/22.
//

#import <Foundation/Foundation.h>

@protocol BCOVPlaybackController;
@protocol BCOVPlaybackSession;

NS_ASSUME_NONNULL_BEGIN

@interface PlaybackConfiguration : NSObject

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong, nullable) id<BCOVPlaybackSession> playbackSession;

@end

NS_ASSUME_NONNULL_END
