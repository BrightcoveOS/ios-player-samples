//
//  AppDelegate.m
//  BasicCastPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <GoogleCast/GoogleCast.h>

#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    BOOL success = [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback
                                                         mode:AVAudioSessionModeMoviePlayback
                                                      options:AVAudioSessionCategoryOptionDuckOthers
                                                        error:&categoryError];

    if (!success)
    {
        NSLog(@"AppDelegate - Error setting AVAudioSession category. Because of this, there may be no sound. %@", categoryError);
    }

    // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#initialize_the_cast_context
    GCKDiscoveryCriteria *discoveryCriteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:kGCKDefaultMediaReceiverApplicationID];
    GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:discoveryCriteria];
    options.physicalVolumeButtonsWillControlDeviceVolume = YES;
    [GCKCastContext setSharedInstanceWithOptions:options];

    // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#add_expanded_controller
    GCKCastContext.sharedInstance.useDefaultExpandedMediaControls = YES;

    // More Info @ https://developers.google.com/cast/docs/ios_sender/integrate#add_mini_controllers
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"NavController"];
    self.castContainerViewController = [GCKCastContext.sharedInstance createCastContainerControllerForViewController:navigationController];
    self.castContainerViewController.miniMediaControlsItemEnabled = YES;

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = self.castContainerViewController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
