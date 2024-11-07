//
//  NowPlayingHandler.h
//  VideoCloudBasicPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;


@interface NowPlayingHandler : NSObject

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController;
- (void)updateNowPlayingInfoForAudioOnly;

@end
