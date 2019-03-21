//
//  VideoPreloadManager.h
//  VideoCloudBasicPlayer
//
//  Created by Jeremy Blaker on 3/21/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCOVVideo;
@class BCOVPUIPlayerView;
@protocol BCOVPlaybackControllerDelegate;
@protocol BCOVPlaybackSession;

NS_ASSUME_NONNULL_BEGIN

@interface VideoPreloadManager : NSObject

- (instancetype)initWithPlaybackControllerDelegate:(id<BCOVPlaybackControllerDelegate> _Nonnull)delegate andPlayerView:(BCOVPUIPlayerView * _Nonnull)playerView andShouldAutoPlay:(BOOL)shouldAutoPlay;
- (void)preloadNextVideoIfNeccessary:(id<BCOVPlaybackSession> _Nonnull)session;
- (void)currentVideoDidCompletePlayback;

@property (nonatomic, strong) NSArray<BCOVVideo *> *videos;

@end

NS_ASSUME_NONNULL_END
