//
//  AppDelegate.m
//  BasicCastPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import "AppDelegate.h"

@import GoogleCast;
@import AVFoundation;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Set the AVAudioSession category to allow audio playback in the background
    // or when the mute button is on. Refer to the AVAudioSession Class Reference:
    // https://developer.apple.com/documentation/avfoundation/avaudiosession
    
    NSError *categoryError = nil;
    // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
    // and https://developer.apple.com/documentation/avfoundation/avaudiosessionmodemovieplayback
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionDuckOthers error:&categoryError];
    if (!success)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. `%@`", categoryError);
    }
    
    // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#initialize_the_cast_context
    GCKDiscoveryCriteria *discoveryCriteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:@"4F8B3483"];
    GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:discoveryCriteria];
    [GCKCastContext setSharedInstanceWithOptions:options];
    
    // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#add_expanded_controller
    [GCKCastContext sharedInstance].useDefaultExpandedMediaControls = YES;
    
    // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#add_mini_controllers
    UIStoryboard *appStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationController = [appStoryboard instantiateViewControllerWithIdentifier:@"NavController"];
    GCKUICastContainerViewController *castContainerVC = [[GCKCastContext sharedInstance] createCastContainerControllerForViewController:navigationController];
    castContainerVC.miniMediaControlsItemEnabled = YES;

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = castContainerVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
