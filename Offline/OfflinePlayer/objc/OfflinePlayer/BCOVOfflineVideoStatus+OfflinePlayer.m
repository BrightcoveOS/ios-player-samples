//
//  BCOVOfflineVideoStatus+OfflinePlayer.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "UIDevice+OfflinePlayer.h"

#import "BCOVOfflineVideoStatus+OfflinePlayer.h"


@implementation BCOVOfflineVideoStatus (OfflinePlayer)

- (BCOVVideo *)offlineVideo
{
    return [BCOVOfflineVideoManager.sharedManager
            videoObjectFromOfflineVideoToken:self.offlineVideoToken];
}

- (NSString *)infoForDonwloadState
{
    switch (self.downloadState)
    {
        case BCOVOfflineVideoDownloadStateRequested:
            return @"download requested";

        case BCOVOfflineVideoDownloadStateDownloading:
        {
            double actualMegabytes = [UIDevice.currentDevice
                                      usedDiskSpaceForVideo:self.offlineVideo];
            double totalDownloadTime = NSDate.timeIntervalSinceReferenceDate - self.downloadStartTime.timeIntervalSinceReferenceDate;
            double mbps = (actualMegabytes * self.downloadPercent / 100) / totalDownloadTime;
            NSString *speed = [NSString stringWithFormat:@"%0.2f %@",
                               (mbps < 0.5 ? mbps * 1000 : mbps),
                               (mbps < 0.5 ? @"KB/s" : @"MB/s")];
            NSString *time = [NSString stringWithFormat:@"%0.1f secs",
                              (totalDownloadTime < 60 ? totalDownloadTime : (totalDownloadTime / 60))];
            return [NSString stringWithFormat:@"downloading (%@ @ %@)\nProgress: %0.2f%%", speed, time, self.downloadPercent];
        }

        case BCOVOfflineVideoDownloadStateSuspended:
            return [NSString stringWithFormat:@"paused (%0.1f%%)",
                    self.downloadPercent];

        case BCOVOfflineVideoDownloadStateCancelled:
            return @"cancelled";

        case BCOVOfflineVideoDownloadStateCompleted:
        {
            double actualMegabytes = [UIDevice.currentDevice
                                      usedDiskSpaceForVideo:self.offlineVideo];
            double totalDownloadTime = self.downloadEndTime.timeIntervalSinceReferenceDate - self.downloadStartTime.timeIntervalSinceReferenceDate;
            double mbps = actualMegabytes / totalDownloadTime;
            NSString *speed = [NSString stringWithFormat:@"%0.2f %@",
                               (mbps < 0.5 ? mbps * 1000 : mbps),
                               (mbps < 0.5 ? @"KB/s" : @"MB/s")];
            NSString *time = [NSString stringWithFormat:@"%0.1f secs",
                              (totalDownloadTime < 60 ? totalDownloadTime : (totalDownloadTime / 60))];
            return [NSString stringWithFormat:@"complete (%@ @ %@)", speed, time];
        }

        case BCOVOfflineVideoDownloadStateError:
        {
            if (!self.error)
            {
                return @"unknown error occured";
            }

            if ([self.error isKindOfClass:NSError.class])
            {
                return [NSString stringWithFormat:@"error %li (%@)",
                        self.error.code,
                        self.error.localizedDescription];
            }

            return @"unknown error";
        }

        case BCOVOfflineVideoDownloadLicensePreloaded:
            return @"license preloaded";

        default:
            return @"unknown state";
    }
}

@end
