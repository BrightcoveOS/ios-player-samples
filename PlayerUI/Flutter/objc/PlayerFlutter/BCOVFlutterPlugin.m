//
//  BCOVFlutterPlugin.m
//  PlayerFlutter
//
//  Created by Carlos Ceja.
//

#import "BCOVFlutterPlugin.h"

#import "BCOVVideoPlayer.h"


@implementation BCOVFlutterPlugin

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar
{
    BCOVVideoPlayerFactory *factory = [[BCOVVideoPlayerFactory alloc] initWithRegistrar:registrar];
    [registrar registerViewFactory:factory withId:@"bcov.flutter/player_view"];
}

@end
