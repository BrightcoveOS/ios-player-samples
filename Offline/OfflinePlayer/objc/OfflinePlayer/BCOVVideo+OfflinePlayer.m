//
//  BCOVVideo+OfflinePlayer.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "BCOVVideo+OfflinePlayer.h"


@implementation BCOVVideo (OfflinePlayer)

- (NSString *)accountId
{
    return self.properties[kBCOVVideoPropertyKeyAccountId];
}

- (NSString *)videoId
{
    return self.properties[kBCOVVideoPropertyKeyId];
}

- (NSString *)localizedName
{
    return localizedNameForLocale(self, nil);
}

- (NSString *)localizedShortDescription
{
    return localizedShortDescriptionForLocale(self, nil);
}

- (NSString *)duration
{
    NSNumber *durationNumber = self.properties[kBCOVVideoPropertyKeyDuration];
    if (durationNumber == nil)
    {
        return @"";
    }

    int totalSeconds = durationNumber.intValue / 1000;
    int hours = floor(totalSeconds / 3600);
    int minutes = floor(totalSeconds % 3600 / 60);
    int seconds = floor(totalSeconds % 3600 % 60);

    return (hours > 0 ?
            [NSString stringWithFormat:@"%i:%02i:%02i", hours, minutes, seconds] :
            [NSString stringWithFormat:@"%02i:%02i", minutes, seconds]);
}

- (NSString *)offlineVideoToken
{
    return self.properties[kBCOVOfflineVideoTokenPropertyKey];
}

- (NSString *)license
{
    if (!self.usesFairPlay)
    {
        return @"clear";
    }


    NSNumber *purchaseNumber = self.properties[kBCOVFairPlayLicensePurchaseKey];
    if (purchaseNumber.boolValue)
    {
        return @"purchase";
    }

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;

    NSDate *expirationDate;
    NSNumber *absoluteExpirationNumber = self.properties[kBCOVOfflineVideoLicenseAbsoluteExpirationTimePropertyKey];
    if (absoluteExpirationNumber && absoluteExpirationNumber.doubleValue > 0.0f)
    {
        NSTimeInterval absoluteExpirationTime = absoluteExpirationNumber.doubleValue;
        expirationDate = [NSDate dateWithTimeIntervalSinceReferenceDate:absoluteExpirationTime];

        NSNumber *playDurationNumber = self.properties[kBCOVFairPlayLicensePlayDurationKey];
        NSNumber *initialPlayNumber = self.properties[kBCOVOfflineVideoInitialPlaybackTimeKey];
        if ((playDurationNumber && playDurationNumber.doubleValue > 0.0f) && initialPlayNumber)
        {
            NSTimeInterval initialPlayTime = initialPlayNumber.doubleValue;
            NSDate *initialPlayDate = [NSDate dateWithTimeIntervalSinceReferenceDate:initialPlayTime];
            NSDate *playDurationExpirationDate = [initialPlayDate dateByAddingTimeInterval:playDurationNumber.doubleValue];
            if (absoluteExpirationNumber.doubleValue > playDurationExpirationDate.timeIntervalSinceReferenceDate)
            {
                expirationDate = playDurationExpirationDate;
            }
        }

        return [NSString stringWithFormat:@"rental (expires %@)",
                [dateFormatter stringFromDate:expirationDate]];
    }
    else
    {
        NSNumber *rentalDurationNumber = self.properties[kBCOVFairPlayLicenseRentalDurationKey];
        NSNumber *startTimeNumber = self.properties[kBCOVOfflineVideoDownloadStartTimePropertyKey];
        if ((rentalDurationNumber && rentalDurationNumber.doubleValue > 0.0f) &&
            (startTimeNumber && startTimeNumber.doubleValue > 0.0f))
        {
            NSTimeInterval rentalDurationTime = rentalDurationNumber.doubleValue;
            NSTimeInterval startTime = startTimeNumber.doubleValue;
            NSDate *startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
            expirationDate = [startDate dateByAddingTimeInterval:rentalDurationTime];

            return [NSString stringWithFormat:@"rental (expires %@)",
                    [dateFormatter stringFromDate:expirationDate]];
        }
    }

    return @"unknown license";
}

- (BOOL)matchesWithVideo:(BCOVVideo *)video
{
    // Returns YES if the two video objects reference the same video asset.
    // Specifically, they have the same account and same video Id.
    NSString *v1Account = self.accountId;
    NSString *v1Id = self.videoId;
    NSString *v2Account = video.accountId;
    NSString *v2Id = video.videoId;

    return ([v1Account isEqualToString:v2Account] &&
            [v1Id isEqualToString:v2Id]);
}

@end
