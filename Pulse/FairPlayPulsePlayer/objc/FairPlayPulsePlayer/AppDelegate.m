//
//  AppDelegate.m
//  FairPlayPulsePlayer
//
//  Created by Carlos Ceja on 2/7/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#if !TARGET_OS_TV
#import <Pulse/Pulse.h>
#else
#import <Pulse_tvOS/Pulse.h>
#endif

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [OOPulse logDebugMessages:YES];
    /*
     Set the AVAudioSession category to allow audio playback when:
     1: Silent Mode is enabled, or
     2: When the app is in the background, and
     2a:`allowsBackgroundAudioPlayback` is enabled on the playback controller, and/or
     2b:`allowsExternalPlayback` is enabled on the playback controller, and
     2c: "Audio, AirPlay, and Picture in Picture" is enabled as a Background Mode capability.
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
    
    // Override point for customization after application launch.
    return YES;
}
                            
@end
