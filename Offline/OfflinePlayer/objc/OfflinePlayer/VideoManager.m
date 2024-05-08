//
//  VideoManager.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVVideo+OfflinePlayer.h"
#import "DownloadManager.h"
#import "Notifications.h"
#import "SettingsViewController.h"
#import "UITabBarController+OfflinePlayer.h"

#import "VideoManager.h"


NSString * const kAccountId = @"5434391461001";
NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
NSString * const kPlaylistRefId = @"brightcove-native-sdk-plist";


@interface VideoManager ()

@property (nonatomic, readwrite, strong) NSArray *videos;
@property (nonatomic, readwrite, strong) NSMutableDictionary *thumbnails;
@property (nonatomic, readwrite, strong) NSMutableDictionary *downloadSize;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;

@end


@implementation VideoManager

+ (instancetype)shared
{
    static VideoManager *videoManager;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        videoManager = [VideoManager new];
    });

    return videoManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.playbackService = ({
            BCOVPlaybackServiceRequestFactory *factory =
            [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kAccountId
                                                               policyKey:kPolicyKey];

            [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
        });
    }

    return self;
}

- (void)retrievePlaylistWithConfiguration:(NSDictionary *)configuration
                          queryParameters:(NSDictionary *)queryParameters
                               completion:(void (^)(BCOVPlaylist *playlist,
                                                    NSDictionary *jsonResponse,
                                                    NSError *error))completionHandler
{
    [self.playbackService findPlaylistWithConfiguration:configuration
                                        queryParameters:queryParameters
                                             completion:^(BCOVPlaylist *playlist,
                                                          NSDictionary *jsonResponse,
                                                          NSError *error) {
        completionHandler(playlist, jsonResponse, error);
    }];
}

- (void)retrieveVideo:(BCOVVideo *)video
           completion:(void (^)(BCOVVideo *video,
                                NSDictionary *jsonResponse,
                                NSError *error))completionHandler
{
    NSDictionary *configuration = @{
        kBCOVPlaybackServiceConfigurationKeyAssetID: video.videoId
    };

    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:nil
                                          completion:^(BCOVVideo *video,
                                                       NSDictionary *jsonResponse,
                                                       NSError *error) {

        completionHandler(video, jsonResponse, error);
    }];
}

- (void)usePlaylist:(NSArray *)playlist
        withBitrate:(UInt64)bitrate
{
    self.videos = playlist;
    self.thumbnails = @{}.mutableCopy;
    self.downloadSize = @{}.mutableCopy;

    for (BCOVVideo *video in self.videos)
    {
        [self estimateDownloadSizeForVideo:video
                               withBitrate:bitrate];

        [self cacheThumbnailForVideo:video];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                          object:nil];
    });
}

- (void)estimateDownloadSizeForVideo:(BCOVVideo *)video
                         withBitrate:(UInt64)bitrate
{
    NSDictionary *options = @{ kBCOVOfflineVideoManagerRequestedBitrateKey: @(bitrate) };

    __weak typeof(self) weakSelf = self;
    [BCOVOfflineVideoManager.sharedManager estimateDownloadSize:video
                                                        options:options
                                                     completion:^(double megabytes,
                                                                  NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.downloadSize[video.videoId] = @(megabytes);

            [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                              object:video];
        });
    }];
}

- (void)cacheThumbnailForVideo:(BCOVVideo *)video
{
    NSDictionary *sources = video.properties[kBCOVVideoPropertyKeyThumbnailSources];

    for (NSDictionary *thumbnail in sources)
    {
        NSString *urlString = thumbnail[@"src"];
        NSURL *url = [NSURL URLWithString:urlString];
        if ([url.scheme caseInsensitiveCompare:kBCOVSourceURLSchemeHTTPS] == NSOrderedSame)
        {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *thumbnailImageData = [NSData dataWithContentsOfURL:url];
                UIImage *thumbnailImage = [UIImage imageWithData:thumbnailImageData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    strongSelf.thumbnails[video.videoId] = thumbnailImage;
                    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                                      object:video];
                });
            });
        }
    }
}

@end
