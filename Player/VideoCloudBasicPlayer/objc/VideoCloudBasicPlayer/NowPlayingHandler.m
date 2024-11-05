//
//  NowPlayingHandler.m
//  VideoCloudBasicPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "NowPlayingHandler.h"


static void * const KVOContext = (void*)&KVOContext;


@interface NowPlayingHandler () <BCOVPlaybackSessionConsumer>

@property (nonatomic, weak) id<BCOVPlaybackSession> session;
@property (nonatomic, strong) NSMutableDictionary *nowPlayingInfo;

@end


@implementation NowPlayingHandler

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController
{
    if (self = [super init])
    {
        [playbackController addSessionConsumer:self];

        MPRemoteCommandCenter *center = MPRemoteCommandCenter.sharedCommandCenter;

        [center.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            [playbackController pause];

            return MPRemoteCommandHandlerStatusSuccess;
        }];

        [center.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            [playbackController play];

            return MPRemoteCommandHandlerStatusSuccess;
        }];

        [center.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {

            MPChangePlaybackPositionCommandEvent *playbackPositionCommandEvent = (MPChangePlaybackPositionCommandEvent *)event;
            CMTime seconds = CMTimeMakeWithSeconds(playbackPositionCommandEvent.positionTime, 600);
            [playbackController seekToTime:seconds completionHandler:nil];

            return MPRemoteCommandHandlerStatusSuccess;
        }];

        __weak typeof(self) weakSelf = self;
        [center.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (strongSelf.session.player.timeControlStatus == AVPlayerTimeControlStatusPaused)
            {
                [playbackController play];
            } else {
                [playbackController pause];
            }

            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }

    return self;
}

- (void)setSession:(id<BCOVPlaybackSession>)session
{
    if (_session)
    {
        [(NSObject *)_session removeObserver:self
                                  forKeyPath:@"player.rate"];
    }

    [(NSObject *)session addObserver:self
                          forKeyPath:@"player.rate"
                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                             context:KVOContext];

    _session = session;
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


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if (context != KVOContext)
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
        return;
    }

    if ([object isEqual:self.session] &&
        [keyPath isEqualToString:@"player.rate"])
    {
        MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;
        NSNumber *rateNumber = change[NSKeyValueChangeNewKey];
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rateNumber;
        infoCenter.nowPlayingInfo = self.nowPlayingInfo;
    }
}


#pragma mark - BCOVPlaybackSessionConsumer

- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.session = session;

    MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;

    self.nowPlayingInfo = @{}.mutableCopy;
    self.nowPlayingInfo[MPMediaItemPropertyTitle] = [session.video localizedNameForLocale:nil];

    NSNumber *durationNumber = session.video.properties[BCOVVideo.PropertyKeyDuration];
    self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(durationNumber.doubleValue / 1000);

    infoCenter.nowPlayingInfo = self.nowPlayingInfo;

    NSString *posterURL = session.video.properties[BCOVVideo.PropertyKeyPoster];
    NSURL *url = [NSURL URLWithString:posterURL];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:imageData];
        self.nowPlayingInfo[MPMediaItemPropertyArtwork] =
        [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size
                                        requestHandler:^UIImage * _Nonnull(CGSize size) {
            return image;
        }];
        infoCenter.nowPlayingInfo = self.nowPlayingInfo;
    });
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session
          didProgressTo:(NSTimeInterval)progress
{
    MPNowPlayingInfoCenter *infoCenter = MPNowPlayingInfoCenter.defaultCenter;
    self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(progress);
    infoCenter.nowPlayingInfo = self.nowPlayingInfo;
}

@end
