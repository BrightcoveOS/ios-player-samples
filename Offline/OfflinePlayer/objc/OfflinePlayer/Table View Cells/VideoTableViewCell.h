//
//  VideoTableViewCell.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/28/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCOVVideo, BCOVOfflineVideoStatus;

typedef NS_ENUM(NSInteger, VideoState)
{
    VideoStateOnlineOnly = 0,
    VideoStateDownloadable,
    VideoStateDownloading,
    VideoStatePaused,
    VideoStateCancelled,
    VideoStateDownloaded,
    VideoStateError
};

NS_ASSUME_NONNULL_BEGIN

@protocol VideoTableViewCellDelegate <NSObject>

- (void)downloadButtonTappedForVideo:(BCOVVideo *)video;

@end

@interface VideoTableViewCell : UITableViewCell

@property (nonatomic, weak) id<VideoTableViewCellDelegate> delegate;

- (void)setupWithStreamingVideo:(BCOVVideo *)video estimatedDownloadSize:(double)downloadSize thumbnailImage:(UIImage *)thumbnailImage videoState:(VideoState)videoState;
- (void)setupWithOfflineVideo:(BCOVVideo *)video offlineStatus:(BCOVOfflineVideoStatus *)offlineStatus downloadSize:(double)downloadSize;

@end

NS_ASSUME_NONNULL_END
