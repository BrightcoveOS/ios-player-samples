//
//  VideoTableViewCell.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class BCOVVideo;


@protocol VideoTableViewCellDelegate <NSObject>

- (void)performDownloadForVideo:(BCOVVideo *)video;

@end


@interface VideoTableViewCell : UITableViewCell

- (void)setupWithVideo:(BCOVVideo *)video
           andDelegate:(id<VideoTableViewCellDelegate>)delegate;

@end
