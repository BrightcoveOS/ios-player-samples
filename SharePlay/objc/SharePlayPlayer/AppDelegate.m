//
//  AppDelegate.m
//  SharePlayPlayer
//
//  Created by Jeremy Blaker on 6/29/21.
//

#import "AppDelegate.h"

@import AVFoundation;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSError *categoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&categoryError];
    
    if (!success)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. `%@`", categoryError);
    }
    return YES;
}

@end
