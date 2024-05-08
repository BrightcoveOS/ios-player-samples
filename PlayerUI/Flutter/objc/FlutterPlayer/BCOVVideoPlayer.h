//
//  BCOVVideoPlayer.h
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>


@interface BCOVVideoPlayer : NSObject <FlutterPlatformView, FlutterStreamHandler>

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                        viewIdentifier:(int64_t)viewId
                             arguments:(id _Nullable)args;

@end
