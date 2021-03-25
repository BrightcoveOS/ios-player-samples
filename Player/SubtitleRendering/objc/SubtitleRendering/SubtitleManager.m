//
//  SubtitleManager.m
//  SubtitleRendering
//
//  Created by Jeremy Blaker on 3/24/21.
//

#import "SubtitleManager.h"

static NSString * const kSubtitleFontKey = @"FontKey";
static NSString * const kSubtitleColorKey = @"ColorKey";
static NSString * const kSubtitleKey = @"SubtitleKey";
static NSString * const kSubtitleHeightKey = @"SubtitleHeightKey";
static NSString * const kSubtitlePayloadKey = @"PayloadKey";

@interface Subtitle : NSObject

@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) CMTime endTime;
@property (nonatomic, copy) NSString *text;

@end

@implementation Subtitle

@end

@interface SubtitleManager ()

@property (nonatomic, strong) NSURL *subtitleURL;
@property (nonatomic, strong) NSArray<Subtitle *> *subtitles;

@end

@implementation SubtitleManager

- (instancetype)initWithURL:(NSURL *)subtitleURL
{
    if (self = [super init])
    {
        _subtitleURL = subtitleURL;
        [self fetchSubtitleData];
    }
    return self;
}

- (void)fetchSubtitleData
{
    __weak typeof(self) weakSelf = self;
    
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:[NSURLRequest requestWithURL:self.subtitleURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error)
        {
            NSLog(@"SubtitleManager encountered error: %@", error.localizedDescription);
        }
        else
        {
            NSString *subtitleString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [strongSelf parseSubtitleString:subtitleString];
        }
        
    }];
    
    [task resume];
}

- (void)parseSubtitleString:(NSString *)subtitleString
{
    NSArray *lines = [subtitleString componentsSeparatedByString:@"\n"];
    
    NSMutableArray *subtitles = @[].mutableCopy;
    
    Subtitle *currentSubtitle;

    for (NSString *line in lines)
    {
        NSError *regexError;
        
        // This regular expression pattern may need to be adjusted for your
        // subtitle file as the time range pattern may be different
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})" options:NSRegularExpressionCaseInsensitive error:&regexError];
        NSArray *matches = [regex matchesInString:line options:0 range:NSMakeRange(0, line.length)];
        
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
            
            // Add previous subtitle to array, if we have one
            if (currentSubtitle)
            {
                [subtitles addObject:currentSubtitle];
            }
            
            // Create a new instance and assign the time range
            currentSubtitle = [Subtitle new];
            currentSubtitle.startTime = CMTimeMake(startTime, 60);
            currentSubtitle.endTime = CMTimeMake(endTime, 60);
        }

        if (matches.count == 0 && currentSubtitle != nil && line.length > 0)
        {
            if (currentSubtitle.text)
            {
                currentSubtitle.text = [currentSubtitle.text stringByAppendingString:[NSString stringWithFormat:@" %@", line]];
            }
            else
            {
                currentSubtitle.text = line;
            }
        }
    }
    
    self.subtitles = subtitles;
}

- (NSString *)subtitleForTime:(CMTime)time
{
    for (Subtitle *subtitle in self.subtitles)
    {
        if (CMTIME_COMPARE_INLINE(subtitle.startTime, <=, time) && CMTIME_COMPARE_INLINE(subtitle.endTime, >=, time))
        {
            return subtitle.text;
        }
    }
    
    return nil;
}

@end
