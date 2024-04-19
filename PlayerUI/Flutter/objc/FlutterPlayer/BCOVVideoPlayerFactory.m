//
//  BCOVVideoPlayerFactory.m
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "BCOVVideoPlayer.h"

#import "BCOVVideoPlayerFactory.h"


@implementation BCOVVideoPlayerFactory

#pragma mark - FlutterPlatformViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args
{
    return [[BCOVVideoPlayer alloc] initWithFrame:frame
                                   viewIdentifier:viewId
                                        arguments:args];
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec
{
    return FlutterStandardMessageCodec.sharedInstance;
}

@end
