//
//  AppDelegate.m
//  PlayerReactNative
//
//  Created by Carlos Ceja.
//

#import <AVFoundation/AVFoundation.h>

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#import "AppDelegate.h"


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
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionDuckOthers error:&categoryError];
    
    if (!success)
    {
        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. `%@`", categoryError);
    }
    
    RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:@"PlayerReactNative" initialProperties:nil];
    
    if (@available(iOS 13.0, *))
    {
        rootView.backgroundColor =  UIColor.systemBackgroundColor;
    }
    else
    {
        rootView.backgroundColor = UIColor.whiteColor;
    }
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *rootViewController = [UIViewController new];
    rootViewController.view = rootView;
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - RCTBridgeDelegate

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
    return [RCTBundleURLProvider.sharedSettings jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
#else
    return [NSBundle.mainBundle URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
