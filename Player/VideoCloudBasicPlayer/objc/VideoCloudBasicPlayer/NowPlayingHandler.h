//
//  NowPlayingHandler.h
//  VideoCloudBasicPlayer
//
//  Created by Jeremy Blaker on 3/20/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

@import BrightcovePlayerSDK;

NS_ASSUME_NONNULL_BEGIN

@interface NowPlayingHandler : NSObject<BCOVPlaybackSessionConsumer>

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController;

- (void)updateNowPlayingInfoForAudioOnly;

@end

NS_ASSUME_NONNULL_END
