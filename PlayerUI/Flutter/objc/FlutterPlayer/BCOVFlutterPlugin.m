//
//  BCOVFlutterPlugin.m
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "BCOVFlutterPlugin.h"

#import "BCOVVideoPlayerFactory.h"


@implementation BCOVFlutterPlugin

#pragma mark - FlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar
{
    [registrar registerViewFactory:[BCOVVideoPlayerFactory new]
                            withId:@"bcov.flutter/player_view"];
}

@end
