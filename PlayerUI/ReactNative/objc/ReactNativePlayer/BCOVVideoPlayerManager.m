//
//  BCOVVideoPlayerManager.m
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

#import "BCOVVideoPlayer.h"

#import "BCOVVideoPlayerManager.h"


@implementation BCOVVideoPlayerManager

RCT_EXPORT_MODULE(BCOVVideoPlayer)

- (UIView *)view
{
    return [BCOVVideoPlayer new];
}

RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onEvent, RCTDirectEventBlock);

RCT_EXPORT_METHOD(playPause:(nonnull NSNumber *)reactTag
                  isPlaying:(BOOL)isPlaying
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager,
                                        NSDictionary<NSNumber *, UIView *> *viewRegistry)
     {
        BCOVVideoPlayer *player = (BCOVVideoPlayer *)viewRegistry[reactTag];
        if ([player isKindOfClass:[BCOVVideoPlayer class]])
        {
            [player playPause:isPlaying];
        }
    }];
});

RCT_EXPORT_METHOD(thumbnailAtTime:(nonnull NSNumber *)reactTag
                  number:(nonnull NSNumber *)value
                  data:(RCTResponseSenderBlock)data)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager,
                                        NSDictionary<NSNumber *, UIView *> *viewRegistry)
     {
        BCOVVideoPlayer *player = (BCOVVideoPlayer *)viewRegistry[reactTag];
        if ([player isKindOfClass:[BCOVVideoPlayer class]])
        {
            NSURL *thumbnailURL = [player thumbnailAtTime:value];
            if (thumbnailURL)
            {
                data(@[thumbnailURL.absoluteString]);
            }
        }
    }];
}

RCT_EXPORT_METHOD(onSlidingComplete:(nonnull NSNumber *)reactTag
                  number:(nonnull NSNumber *)value
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager,
                                        NSDictionary<NSNumber *, UIView *> *viewRegistry)
     {
        BCOVVideoPlayer *player = (BCOVVideoPlayer *)viewRegistry[reactTag];
        if ([player isKindOfClass:[BCOVVideoPlayer class]])
        {
            [player onSlidingComplete:value];
        }
    }];
});

@end
