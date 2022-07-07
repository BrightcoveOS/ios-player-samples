//
//  VideoTableViewCell.h
//  TableViewPlayer
//
//  Created by Jeremy Blaker on 6/14/22.
//

#import <UIKit/UIKit.h>

@class BCOVVideo;
@class PlaybackConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface VideoTableViewCell : UITableViewCell

- (void)setUpWithVideo:(BCOVVideo *)video playbackConfiguration:(PlaybackConfiguration *)playbackConfiguration;

@end

NS_ASSUME_NONNULL_END
