//
//  VideoTableViewCell.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVVideo+OfflinePlayer.h"
#import "UIDevice+OfflinePlayer.h"
#import "UITableViewCell+OfflinePlayer.h"
#import "VideoManager.h"
#import "VideosViewController.h"

#import "VideoTableViewCell.h"


@interface VideoTableViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic, weak) BCOVVideo *video;
@property (nonatomic, weak) id<VideoTableViewCellDelegate> delegate;

@end


@implementation VideoTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.titleLabel.numberOfLines = 1;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.detailLabel.numberOfLines = 2;
    self.detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.progressView.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.video = nil;
    self.delegate = nil;
    self.titleLabel.text = @"";
    self.detailLabel.text = @"";
}

- (UIImage *)thumbnail
{
    UIImage *thumbnail;

    if (!self.video.offline)
    {
        thumbnail = VideoManager.shared.thumbnails[self.video.videoId];
    }
    else
    {
        NSString *urlPath = self.video.properties[kBCOVOfflineVideoPosterFilePathPropertyKey];
        thumbnail = [UIImage imageWithContentsOfFile:urlPath];
    }

    return thumbnail;
}

- (NSString *)fileSize
{
    if (!self.video.offline)
    {
        NSNumber *downloadSize = VideoManager.shared.downloadSize[self.video.videoId] ?: 0;

        return [NSString stringWithFormat:@"%0.2f MB", downloadSize.doubleValue];
    }
    else
    {
        return [UIDevice.currentDevice usedDiskSpaceWithUnitsForVideo:self.video];
    }
}

- (UIImageView *)actionAccessoryView
{
    UIImageView *imageView = (self.video.canBeDownloaded ?
                              [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:@"arrow.down.circle"]] :
                              nil);

    NSArray *offlineVideoStatusArray = [BCOVOfflineVideoManager.sharedManager offlineVideoStatus];
    for (BCOVOfflineVideoStatus *offlineVideoStatus in offlineVideoStatusArray)
    {
        BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                                   videoObjectFromOfflineVideoToken:offlineVideoStatus.offlineVideoToken];
        if (![offlineVideo matchesWithVideo:self.video])
        {
            continue;
        }

        switch (offlineVideoStatus.downloadState)
        {
            case BCOVOfflineVideoDownloadStateRequested:
            case BCOVOfflineVideoDownloadStateDownloading:
            case BCOVOfflineVideoDownloadLicensePreloaded:
                imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.triangle.circlepath"]];
                break;

            case BCOVOfflineVideoDownloadStateSuspended:
                imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pause.circle"]];
                break;

            case BCOVOfflineVideoDownloadStateCancelled:
            {
                imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"multiply.circle"]];
                imageView.tintColor = UIColor.systemRedColor;
                break;
            }

            case BCOVOfflineVideoDownloadStateCompleted:
                imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.circle"]];
                break;

            case BCOVOfflineVideoDownloadStateError:
            {
                imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"exclamationmark.circle"]];
                imageView.tintColor = UIColor.systemRedColor;
                break;
            }
        }
    }

    if (!self.video.offline && imageView)
    {
        UITapGestureRecognizer *tapGestureRecognize = [UITapGestureRecognizer new];
        [tapGestureRecognize addTarget:self
                                action:@selector(imageTapped:)];

        [imageView addGestureRecognizer:tapGestureRecognize];
        imageView.userInteractionEnabled = YES;
    }

    return imageView;
}

- (void)setVideo:(BCOVVideo *)video
{
    _video = video;

    self.titleLabel.text = video.localizedName ?: @"unknown";
    // Use red label to indicate that the video is protected with FairPlay
    self.titleLabel.textColor = video.usesFairPlay ? [UIColor colorWithRed:0.75
                                                                     green:0.0
                                                                      blue:0.0
                                                                     alpha:1.0] : UIColor.blackColor;

    self.thumbnailImageView.backgroundColor = !self.thumbnail ? UIColor.blackColor : nil;
    self.thumbnailImageView.image = self.thumbnail ?: [UIImage imageNamed:@"AppIcon"];

    self.detailLabel.text = [NSString stringWithFormat:@"%@ / %@\n%@",
                             video.duration,
                             self.fileSize,
                             video.localizedShortDescription ?: @""];

    if (video.offline)
    {
        BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager
                                                      offlineVideoStatusForToken:video.offlineVideoToken];
        self.progressView.hidden = offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateCompleted;
        self.progressView.progress = offlineVideoStatus.downloadPercent / 100;
    }

    self.accessoryView = !(TARGET_OS_SIMULATOR && video.usesFairPlay) ? self.actionAccessoryView : nil;
}

- (void)setupWithVideo:(BCOVVideo *)video
           andDelegate:(id<VideoTableViewCellDelegate>)delegate;
{
    self.delegate = delegate;
    self.video = video;
}

- (void)imageTapped:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if ([self.delegate respondsToSelector:@selector(performDownloadForVideo:)])
        {
            [self.delegate performDownloadForVideo:self.video];
        }
    }
}

@end
