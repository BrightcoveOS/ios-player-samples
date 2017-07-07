//
//  AppDelegate.m
//  FairPlayIMAPlayer
//
//  Copyright © 2017 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>


@implementation AppDelegate

void simulatorCheck()
{
#if (TARGET_OS_SIMULATOR)

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FairPlay Warning" message:@"FairPlay only works on actual iOS devices, not in a simulator.\n\nYou will not be able to view any FairPlay content." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];

#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // FairPlay doesn't work when we're running in a simulator, so put up an alert.
    simulatorCheck();

    // We need the below code in order to ensure that audio plays back when we
    // expect it to. For example, without setting this code, we won't hear the video
    // when the mute switch is on. For simplicity in the sample, we are going to
    // put this in the app delegate.  Check out
    // https://developer.apple.com/Library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    // for more information on how to use this in your own app.

    NSError *categoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&categoryError];

    if (!success)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. `%@`", categoryError);
    }
    
    return YES;
}

@end
