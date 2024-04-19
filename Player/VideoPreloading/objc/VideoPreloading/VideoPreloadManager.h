//
//  VideoPreloadManager.h
//  VideoPreloading
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@interface VideoPreloadManager : NSObject

- (instancetype _Nonnull)initWithPlaybackControllerDelegate:(id<BCOVPlaybackControllerDelegate> _Nonnull)delegate 
                                              andPlayerView:(BCOVPUIPlayerView * _Nonnull)playerView
                                          andShouldAutoPlay:(BOOL)shouldAutoPlay;
- (void)preloadNextVideoIfNeccessary:(id<BCOVPlaybackSession> _Nonnull)session;
- (void)currentVideoDidCompletePlayback;

@property (nonatomic, strong, nullable) NSArray<BCOVVideo *> *videos;

@end
