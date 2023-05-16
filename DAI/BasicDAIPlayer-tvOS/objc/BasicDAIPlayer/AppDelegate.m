//
//  AppDelegate.m
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*
     Set the AVAudioSession category to allow audio playback.
     Refer to the AVAudioSession Class Reference:
     https://developer.apple.com/documentation/avfoundation/avaudiosession
     */

    NSError *categoryError = nil;
    // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
    // and https://developer.apple.com/documentation/avfoundation/avaudiosessionmodemovieplayback
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionDuckOthers error:&categoryError];

    if (!success)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. `%@`", categoryError);
    }

    return YES;
}

@end
