//
//  AppDelegate.m
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Flutter/Flutter.h>

#import "BCOVFlutterPlugin.h"

#import "AppDelegate.h"


@interface AppDelegate ()

@property (nonatomic, readwrite, strong) FlutterEngine *flutterEngine;

@end


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

    // Runs the default Dart entrypoint with a default Flutter route.
    self.flutterEngine = [[FlutterEngine alloc] initWithName:@"io.flutter"];
    [self.flutterEngine run];

    NSObject<FlutterPluginRegistrar> *registrar = [self.flutterEngine registrarForPlugin:@"BCOVFlutterPlugin"];
    [BCOVFlutterPlugin registerWithRegistrar:registrar];

    FlutterViewController *flutterViewController = [[FlutterViewController alloc]
                                                    initWithEngine:self.flutterEngine
                                                    nibName:nil
                                                    bundle:nil];

    self.flutterViewController = flutterViewController;

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = self.flutterViewController;
    [self.window makeKeyAndVisible];

    return YES;;
}

@end
