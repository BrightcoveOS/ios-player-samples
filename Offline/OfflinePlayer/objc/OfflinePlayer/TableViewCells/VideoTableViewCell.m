//
//  VideoTableViewCell.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/28/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "VideoTableViewCell.h"

@import BrightcovePlayerSDK;

@interface VideoTableViewCell ()

@property (nonatomic, weak) BCOVVideo *video;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIImageView *statusButtonImageView;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;

- (IBAction)downloadButtonWasPressed:(id)sender;

@end

// Custom cell implementation to arrange
// text and images more carefully.
// Also adds a download status image.
@implementation VideoTableViewCell : UITableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self cleanup];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self cleanup];
}

- (void)cleanup
{
    self.titleLabel.text = nil;
    self.detailLabel.text = nil;
    self.thumbnailImageView.image = nil;
    self.statusButtonImageView.image = nil;
}

- (IBAction)downloadButtonWasPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(downloadButtonTappedForVideo:)])
    {
        [self.delegate downloadButtonTappedForVideo:self.video];
    }
}

- (void)setupWithStreamingVideo:(BCOVVideo *)video estimatedDownloadSize:(double)downloadSize thumbnailImage:(UIImage *)thumbnailImage videoState:(VideoState)videoState
{
    self.video = video;
    
    self.progressView.hidden = YES;
    
    [self setupTitleLabel];
    
    NSString *detailString = self.video.properties[kBCOVVideoPropertyKeyDescription];
    if ((detailString == nil) || (detailString.length == 0))
    {
        detailString = self.video.properties[kBCOVVideoPropertyKeyReferenceId] ?: @"nil";
    }

    NSNumber *durationNumber = self.video.properties[kBCOVVideoPropertyKeyDuration];
    // raw duration is in milliseconds
    int duration = durationNumber.intValue / 1000;

    self.detailLabel.text = [NSString stringWithFormat:@"%d sec / %0.2f MB\n%@", duration, downloadSize, detailString];

    self.thumbnailImageView.image = thumbnailImage = thumbnailImage ?: [UIImage imageNamed:@"bcov"];
    
    [self setStateImage:videoState];
}

- (void)setupWithOfflineVideo:(BCOVVideo *)video offlineStatus:(BCOVOfflineVideoStatus *)offlineStatus downloadSize:(double)downloadSize
{
    self.video = video;
    
    self.progressView.hidden = NO;
    
    [self setupTitleLabel];
    
    NSString *detailString = video.properties[kBCOVVideoPropertyKeyDescription];
    if ((detailString == nil) || (detailString.length == 0))
    {
        detailString = video.properties[kBCOVVideoPropertyKeyReferenceId] ?: @"";
    }

    // Detail text is two lines consisting of:
    // "duration in seconds / actual download size)"
    // "reference_id"
    NSNumber *durationNumber = video.properties[kBCOVVideoPropertyKeyDuration];
    // raw duration is in milliseconds
    int duration = durationNumber.intValue / 1000;
    NSString *twoLineDetailString;
    
    if (offlineStatus.downloadState == BCOVOfflineVideoDownloadStateCompleted)
    {
        // Use Kilobytes if the measurement is too small
        if (downloadSize < 0.5)
        {
            double kilobytes = downloadSize * 1000.0;
            twoLineDetailString = [NSString stringWithFormat:@"%d sec / %0.2f KB\n%@",
                                   duration, kilobytes,
                                   detailString];
        }
        else
        {
            twoLineDetailString = [NSString stringWithFormat:@"%d sec / %0.2f MB\n%@",
                                   duration, downloadSize,
                                   detailString];
        }
    }
    else
    {
        // download not complete: skip the download size
        twoLineDetailString = [NSString stringWithFormat:@"%d sec / %@ MB\n%@",
                               duration, @"--",
                               detailString];
    }
    
    self.detailLabel.text = twoLineDetailString;
    
    NSString *thumbnailPathString = video.properties[kBCOVOfflineVideoThumbnailFilePathPropertyKey];
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailPathString];

    // Set up the image view
    // Use a default image if the cached image is not available
    self.thumbnailImageView.image = thumbnailImage ?: [UIImage imageNamed:@"bcov"];
    
    if (offlineStatus == nil)
    {
        [self setStateImage:VideoStateOnlineOnly];
    }
    else
    {
        switch (offlineStatus.downloadState)
        {
            case BCOVOfflineVideoDownloadLicensePreloaded:
            case BCOVOfflineVideoDownloadStateRequested:
            case BCOVOfflineVideoDownloadStateTracksRequested:
            case BCOVOfflineVideoDownloadStateDownloading:
            case BCOVOfflineVideoDownloadStateTracksDownloading:
                [self setStateImage:VideoStateDownloading];
                break;
            case BCOVOfflineVideoDownloadStateSuspended:
            case BCOVOfflineVideoDownloadStateTracksSuspended:
                [self setStateImage:VideoStatePaused];
                break;
            case BCOVOfflineVideoDownloadStateCancelled:
            case BCOVOfflineVideoDownloadStateTracksCancelled:
                [self setStateImage:VideoStateCancelled];
                break;
            case BCOVOfflineVideoDownloadStateCompleted:
            case BCOVOfflineVideoDownloadStateTracksCompleted:
                [self setStateImage:VideoStateDownloaded];
                break;
            case BCOVOfflineVideoDownloadStateError:
            case BCOVOfflineVideoDownloadStateTracksError:
                [self setStateImage:VideoStateError];
                break;
        }
    }
    
    self.progressView.progress = offlineStatus.downloadPercent / 100;
}

- (void)setupTitleLabel
{
    self.titleLabel.text = self.video.properties[kBCOVVideoPropertyKeyName];
    self.titleLabel.textColor = (self.video.usesFairPlay ? [UIColor colorWithRed:0.75 green:0.0 blue:0.0 alpha:1.0] : UIColor.blackColor);
}

- (void)setStateImage:(VideoState)state
{
    UIImage *newImage = nil;
    switch (state)
    {
        case VideoStateOnlineOnly: // nothing
        {
            break;
        }
        case VideoStateDownloadable:
        {
            newImage = [UIImage imageNamed:@"download"];
            break;
        }
        case VideoStateDownloading:
        {
            newImage = [UIImage imageNamed:@"inprogress"];
            break;
        }
        case VideoStatePaused:
        {
            newImage = [UIImage imageNamed:@"paused"];
            break;
        }
        case VideoStateDownloaded:
        {
            newImage = [UIImage imageNamed:@"downloaded"];
            break;
        }
        case VideoStateCancelled:
        {
            newImage = [UIImage imageNamed:@"cancelled"];
            break;
        }
        case VideoStateError:
        {
            newImage = [UIImage imageNamed:@"error"];
            break;
        }
    }

    self.statusButtonImageView.image = newImage;
}

@end
