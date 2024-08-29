//
//  BCOVThumbnailManager.m
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "BCOVThumbnailManager.h"

@implementation BCOVThumbnail

@end


#pragma mark -

@interface BCOVThumbnailManager ()

@property (nonatomic, readwrite, strong) NSArray<BCOVThumbnail *> *thumbnails;

@end


@implementation BCOVThumbnailManager

- (instancetype)initWithURL:(NSURL *)thumbnailsURL
{
    if (self = [super init])
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:thumbnailsURL];

        __weak typeof(self) weakSelf = self;

        [[NSURLSession.sharedSession dataTaskWithRequest:request
                                       completionHandler:^(NSData * _Nullable data,
                                                           NSURLResponse * _Nullable response,
                                                           NSError * _Nullable error) {

            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (error)
            {
                NSLog(@"BCOVThumbnailManager encountered error: %@", error.localizedDescription);
            }
            else
            {
                NSString *thumbnailString = [[NSString alloc] initWithData:data
                                                                 encoding:NSUTF8StringEncoding];
                [strongSelf parseThumbnailString:thumbnailString];
            }

        }] resume];
    }

    return self;
}

- (NSURL *)thumbnailAtTime:(CMTime)time
{
    for (BCOVThumbnail *thumbnail in self.thumbnails)
    {
        if (CMTIME_COMPARE_INLINE(thumbnail.startTime, <=, time) &&
            CMTIME_COMPARE_INLINE(thumbnail.endTime, >=, time))
        {
            return thumbnail.url;
        }
    }

    return nil;
}

- (void)parseThumbnailString:(NSString *)thumbnail
{
    NSMutableArray *thumbnails = @[].mutableCopy;

    NSArray *lines = [thumbnail componentsSeparatedByString:@"\n"];
    for (NSString *line in lines)
    {
        NSError *regexError;

        // This regular expression pattern may need to be adjusted for your
        // thumbnail file as the time range pattern may be different
        NSString *regexString = @"([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&regexError];
        NSArray *matches = [regex matchesInString:line
                                          options:0
                                            range:NSMakeRange(0, line.length)];

        if (regexError)
        {
            NSLog(@"Error: %@", regexError.localizedDescription);
            break;
        }

        if (matches.count == 1)
        {
            NSTextCheckingResult *result = matches.firstObject;

            // If you had to adjust the regular expression pattern above
            // you will need to adjust the startTime and endTime values
            // based on the additional data available
            double startTime = ([[line substringWithRange:[result rangeAtIndex:1]] doubleValue] * 60.0 * 60.0) + [[line substringWithRange:[result rangeAtIndex:2]] doubleValue] * 60.0 + ([[line substringWithRange:[result rangeAtIndex:3]] doubleValue] / 1000.0);

            double endTime = ([[line substringWithRange:[result rangeAtIndex:4]] doubleValue] * 60.0 * 60.0) + [[line substringWithRange:[result rangeAtIndex:5]] doubleValue] * 60.0 + ([[line substringWithRange:[result rangeAtIndex:6]] doubleValue] / 1000.0);

            // Create a new instance and assign the time range
            BCOVThumbnail *thumbnail = [BCOVThumbnail new];
            thumbnail.startTime = CMTimeMake(startTime, 60);
            thumbnail.endTime = CMTimeMake(endTime, 60);

            [thumbnails addObject:thumbnail];
        }

        if (matches.count == 0 && line.length > 0)
        {
            BCOVThumbnail *currentThumbnail = thumbnails.lastObject;
            if (currentThumbnail)
            {
                currentThumbnail.url = [NSURL URLWithString:line];
            }
        }
    }

    self.thumbnails = thumbnails;
}

@end
