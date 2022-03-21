//
//  AppDelegate.m
//  PlayerFlutter
//
//  Created by Carlos Ceja.
//

#import <AVFoundation/AVFoundation.h>

#import "AppDelegate.h"

#import "BCOVFlutterPlugin.h"


@interface AppDelegate ()

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
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
    AVAudioSession *audioSession = AVAudioSession.sharedInstance;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&categoryError] && [audioSession setActive:YES error:&categoryError];
    if (!success)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. `%@`", categoryError);
    }
    
    NSObject<FlutterPluginRegistrar> *registrar = [self registrarForPlugin:@"BCOVFlutterPlugin"];
    [BCOVFlutterPlugin registerWithRegistrar:registrar];
    
    // Override point for customization after application launch.
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
