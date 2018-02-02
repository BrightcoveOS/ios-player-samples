//
//  AppDelegate.m
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2018 Brightcove. All rights reserved.
//

@import BrightcovePlayerSDK;

#import <AVFoundation/AVFoundation.h>

#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"willFinishLaunchingWithOptions:\n%@", launchOptions);

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    if (setCategoryError)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. %@", setCategoryError);
    }

    NSLog(@"didFinishLaunchingWithOptions:\n%@", launchOptions);
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"performFetchWithCompletionHandler:");
    
    if (completionHandler != nil)
    {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"handleEventsForBackgroundURLSession: %@", identifier);
    
    completionHandler();
}

@end
