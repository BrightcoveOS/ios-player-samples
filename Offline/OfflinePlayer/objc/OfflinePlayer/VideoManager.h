//
//  VideoManager.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BCOVPlaylist;
@class BCOVVideo;


extern NSString * const kPlaylistRefId;


@interface VideoManager : NSObject

@property (nonatomic, readonly, strong) NSArray *videos;
@property (nonatomic, readonly, strong) NSMutableDictionary *thumbnails;
@property (nonatomic, readonly, strong) NSMutableDictionary *downloadSize;

+ (instancetype)shared;

- (void)retrievePlaylistWithConfiguration:(NSDictionary *)configuration
                          queryParameters:(NSDictionary *)queryParameters
                               completion:(void (^)(BCOVPlaylist *playlist,
                                                    NSDictionary *jsonResponse,
                                                    NSError *error))completionHandler;

- (void)retrieveVideo:(BCOVVideo *)video
           completion:(void (^)(BCOVVideo *video,
                                NSDictionary *jsonResponse,
                                NSError *error))completionHandler;

- (void)usePlaylist:(NSArray *)playlist
        withBitrate:(UInt64)bitrate;

@end
