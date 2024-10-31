//
//  UIDevice+OfflinePlayer.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;

#import "UIDevice+OfflinePlayer.h"


@implementation UIDevice (OfflinePlayer)

- (NSString *)freeDiskSpace
{
    return [self GBFormatter:self.freeDiskSpaceInBytes];
}

- (NSString *)totalDiskSpace
{
    return [self GBFormatter:self.totalDiskSpaceInBytes];
}

- (NSString *)usedDiskSpaceWithUnitsForVideo:(BCOVVideo *)video
{
    NSString *videoFilePath = video.properties[kBCOVOfflineVideoFilePathPropertyKey];
    UInt64 usedSpaceDisk = [self getDiskSpaceForFolderPath:videoFilePath];

    return [self Formatter:usedSpaceDisk
               includeUnit:YES];
}

- (double)usedDiskSpaceForVideo:(BCOVVideo *)video
{
    NSString *videoFilePath = video.properties[kBCOVOfflineVideoFilePathPropertyKey];
    UInt64 usedSpaceDisk = [self getDiskSpaceForFolderPath:videoFilePath];

    return [self Formatter:usedSpaceDisk
               includeUnit:NO].doubleValue;
}

- (NSString *)Formatter:(UInt64)bytes
            includeUnit:(BOOL)includeUnit
{
    NSByteCountFormatter *formatter = [NSByteCountFormatter new];
    formatter.allowedUnits = NSByteCountFormatterUseMB;
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    formatter.includesUnit = includeUnit;
    formatter.includesCount = YES;
    formatter.zeroPadsFractionDigits = YES;

    return [formatter stringFromByteCount:bytes];
}

- (NSString *)GBFormatter:(UInt64)bytes
{
    NSByteCountFormatter *formatter = [NSByteCountFormatter new];
    formatter.allowedUnits = NSByteCountFormatterUseGB;
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    formatter.includesUnit = NO;
    formatter.includesCount = YES;
    formatter.zeroPadsFractionDigits = YES;

    return [formatter stringFromByteCount:bytes];
}

- (UInt64)getDiskSpaceForFolderPath:(NSString *)folderPath
{
    UInt64 directorySize = 0;
    @try
    {
        NSArray *filesArray = [NSFileManager.defaultManager subpathsAtPath:folderPath];
        for (NSString *fileName in filesArray)
        {
            NSString *path = [NSString stringWithFormat:@"%@/%@",
                              folderPath, fileName];
            NSDictionary *fileDictionary =
            [NSFileManager.defaultManager attributesOfItemAtPath:path
                                                           error:nil];
            NSNumber *filesize = fileDictionary[NSFileSize];
            directorySize = directorySize + (filesize.unsignedLongLongValue ?: 0);
        }
    }
    @catch (NSError *error)
    {
        NSLog(@"%@", error.localizedDescription);
    }

    return directorySize;
}

- (UInt64)freeDiskSpaceInBytes
{
    NSDictionary *systemAttributes =
    [NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory()
                                                          error:nil];

    NSNumber *fileSystemFreeSize = systemAttributes[NSFileSystemFreeSize];

    return fileSystemFreeSize.unsignedLongLongValue ?: 0;
}

- (UInt64)totalDiskSpaceInBytes
{
    NSDictionary *systemAttributes =
    [NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory()
                                                          error:nil];

    NSNumber *fileSystemSize = systemAttributes[NSFileSystemSize];

    return fileSystemSize.unsignedLongLongValue ?: 0;
}

@end
