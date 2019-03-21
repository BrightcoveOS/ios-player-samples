//
//  VideoPreloadManager.m
//  VideoCloudBasicPlayer
//
//  Created by Jeremy Blaker on 3/21/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "VideoPreloadManager.h"

@import BrightcovePlayerSDK;

static NSTimeInterval const kPreloadNextSessionThreshold = .75; // Translates to 75% of video completed

@interface VideoPreloadManager ()

@property (nonatomic, strong) id<BCOVPlaybackController> playbackControllerAlpha;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackControllerBravo;
@property (nonatomic, assign) BOOL didBeginPreloadingNextSession;
@property (nonatomic, assign) NSInteger currentVideoIndex;
@property (nonatomic, assign) BOOL autoPlayEnabled;

@property (nonatomic, weak) BCOVPUIPlayerView *playerView;

@end

@implementation VideoPreloadManager

- (instancetype)initWithPlaybackControllerDelegate:(id<BCOVPlaybackControllerDelegate>)delegate andPlayerView:(BCOVPUIPlayerView *)playerView andShouldAutoPlay:(BOOL)shouldAutoPlay
{
    if (self = [super init])
    {
        _autoPlayEnabled = shouldAutoPlay;
        
        // Keep a weak reference to the BCOVPUIPlayerView object so we can
        // check which playbackController is set and set the next one
        _playerView = playerView;
        
        _playbackControllerAlpha = [BCOVPlayerSDKManager.sharedManager createPlaybackController];
        _playbackControllerAlpha.delegate = delegate;
        _playbackControllerAlpha.autoAdvance = NO;
        // Use the shouldAutoPlay value here so the initial video
        // will auto play if the value is YES
        _playbackControllerAlpha.autoPlay = _autoPlayEnabled;
        
        _playerView.playbackController = _playbackControllerAlpha;
        
        _playbackControllerBravo = [BCOVPlayerSDKManager.sharedManager createPlaybackController];
        _playbackControllerBravo.delegate = delegate;
        _playbackControllerBravo.autoAdvance = NO;
        // Second playback controller should not autoplay, we will manually play later
        _playbackControllerBravo.autoPlay = NO;
    }
    return self;
}

- (void)setVideos:(NSArray<BCOVVideo *> *)videos
{
    _videos = videos;
    // After getting the videos from our playbackService request
    // we want to play the first video on the initial playbackController
    [self.playbackControllerAlpha setVideos:@[videos.firstObject]];
}

- (BOOL)shouldPreloadNextSession:(id<BCOVPlaybackSession>)currentSession
{
    if (self.didBeginPreloadingNextSession)
    {
        return NO;
    }
    // Determine if the current video is far enough along
    // to preload the next video
    AVPlayer *player = currentSession.player;
    Float64 progressSeconds = CMTimeGetSeconds(player.currentTime);
    Float64 durationSeconds = CMTimeGetSeconds(player.currentItem.duration);
    return ((progressSeconds / durationSeconds) >= kPreloadNextSessionThreshold);
}

- (void)preloadNextSession
{
    NSInteger nextVideoIndex = self.currentVideoIndex + 1;
    
    // We don't want to go out-of-bounds!
    if (nextVideoIndex >= self.videos.count)
    {
        return;
    }
    
    self.didBeginPreloadingNextSession = YES;
    
    // Get the next video in the array
    BCOVVideo *nextVideo = self.videos[nextVideoIndex];
    
    // Get the next playback controller
    // If current is alpha, next will be bravo, and vice versa
    id<BCOVPlaybackController> nextPlaybackController = [self nextPlaybackController];
    // Ensure auto play is disabled
    nextPlaybackController.autoPlay = NO;
    
    // Set the next video on the next controller to
    // begin preloading
    [nextPlaybackController setVideos:@[nextVideo]];
    
    // Save the next video's index as the currentVideoIndex
    self.currentVideoIndex = nextVideoIndex;
}

- (id<BCOVPlaybackController>)nextPlaybackController
{
    if (self.playerView.playbackController == self.playbackControllerAlpha)
    {
        return self.playbackControllerBravo;
    }
    else
    {
        return self.playbackControllerAlpha;
    }
}

- (void)preloadNextVideoIfNeccessary:(id<BCOVPlaybackSession>)session
{
    if ([self shouldPreloadNextSession:session])
    {
        [self preloadNextSession];
    }
}

- (void)currentVideoDidCompletePlayback
{
    // Set the next playback controller, which has the preloaded video,
    // as the playerView's playback controller
    self.playerView.playbackController = [self nextPlaybackController];
    // Play the video if autoPlay is enabled
    if (self.autoPlayEnabled)
    {
        [self.playerView.playbackController play];
    }
    // We can now prepare for the next video to be preloaded
    self.didBeginPreloadingNextSession = NO;
}

@end
