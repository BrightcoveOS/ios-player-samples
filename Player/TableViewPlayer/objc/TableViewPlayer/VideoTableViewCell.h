//
//  VideoTableViewCell.h
//  TableViewPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCOVVideo;
@class PlaybackConfiguration;


@interface VideoTableViewCell : UITableViewCell

- (void)setUpWithVideo:(BCOVVideo *)video
 playbackConfiguration:(PlaybackConfiguration *)playbackConfiguration;

@end
