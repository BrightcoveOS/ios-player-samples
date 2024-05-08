//
//  PlaybackConfiguration.h
//  TableViewPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@interface PlaybackConfiguration : NSObject

@property (nonatomic, strong) id<BCOVPlaybackSession> playbackSession;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@end
