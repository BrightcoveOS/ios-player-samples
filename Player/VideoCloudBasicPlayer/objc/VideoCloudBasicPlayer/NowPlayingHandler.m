//
//  NowPlayingHandler.m
//  VideoCloudBasicPlayer
//
//  Created by Jeremy Blaker on 3/20/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import "NowPlayingHandler.h"

static void * const KVOContext = (void*)&KVOContext;

@interface NowPlayingHandler ()

@property (nonatomic, weak) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) NSMutableDictionary *nowPlayingInfo;
@property (nonatomic, weak) id<BCOVPlaybackSession> session;

@end

@implementation NowPlayingHandler

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController
{
    if (self = [super init])
    {
        _playbackController = playbackController;
        [_playbackController addSessionConsumer:self];
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [(NSObject *)self.session removeObserver:self forKeyPath:@"player.rate"];
}

- (void)updateNowPlayingInfoForAudioOnly
{
    NSDictionary *props = self.session.video.properties;
    
    self.nowPlayingInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypeMusic);

    // These custom_fields values can be configured in VideoCloud
    // https://beacon.support.brightcove.com/syncing-with-video-cloud/vc-custom-fields.html
    NSDictionary *customFields = props[@"custom_fields"];
    if (customFields[@"album_artist"])
    {
        self.nowPlayingInfo[MPMediaItemPropertyArtist] = customFields[@"album_artist"];
    }
    if (customFields[@"album_name"])
    {
        self.nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = customFields[@"album_name"];
    }
    
    MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;
    infoCenter.nowPlayingInfo = self.nowPlayingInfo;
}

- (void)setup
{
    MPRemoteCommandCenter *center = MPRemoteCommandCenter.sharedCommandCenter;

    [center.pauseCommand addTarget:self action:@selector(pauseCommand:)];
    [center.playCommand addTarget:self action:@selector(playCommand:)];
    [center.togglePlayPauseCommand addTarget:self action:@selector(playPauseCommand:)];
}

- (MPRemoteCommandHandlerStatus)pauseCommand:(MPRemoteCommandEvent *)event
{
    [self.playbackController pause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)playCommand:(MPRemoteCommandEvent *)event
{
    [self.playbackController play];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)playPauseCommand:(MPRemoteCommandEvent *)event
{
    if (self.session.player.rate == 0)
    {
        [self.playbackController play];
    }
    else
    {
        [self.playbackController pause];
    }
    
    return MPRemoteCommandHandlerStatusSuccess;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context != KVOContext)
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([object isEqual:self.session] && [keyPath isEqualToString:@"player.rate"])
    {
        MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;
        float rate = [change[NSKeyValueChangeNewKey] floatValue];
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(rate);
        infoCenter.nowPlayingInfo = self.nowPlayingInfo;
    }
}

#pragma mark - Setters

- (void)setSession:(id<BCOVPlaybackSession>)session
{
    if (_session)
    {
        [(NSObject *)_session removeObserver:self forKeyPath:@"player.rate"];
    }
    [(NSObject *)session addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:KVOContext];
    _session = session;
}

#pragma mark - BCOVPlaybackSessionConsumer

- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.session = session;

    MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;
    
    self.nowPlayingInfo = @{}.mutableCopy;
    self.nowPlayingInfo[MPMediaItemPropertyTitle] = localizedNameForLocale(session.video, nil);
    NSNumber *duration = session.video.properties[kBCOVVideoPropertyKeyDuration];
    self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(duration.doubleValue / 1000);
    
    NSString *posterURLString = session.video.properties[kBCOVVideoPropertyKeyPoster];
    NSURL *posterURL = [NSURL URLWithString:posterURLString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:posterURL];
        UIImage *image = [UIImage imageWithData:imageData];
        self.nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size requestHandler:^UIImage * _Nonnull(CGSize size) {
            return image;
        }];
        infoCenter.nowPlayingInfo = self.nowPlayingInfo;
    });
    
    infoCenter.nowPlayingInfo = self.nowPlayingInfo;
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;
    
    self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(progress);
    
    infoCenter.nowPlayingInfo = self.nowPlayingInfo;
}

@end
