//
//  BCOVVideoPlayerManager.m
//  PlayerReactNative
//
//  Created by Carlos Ceja.
//

#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

#import "PlayerReactNative-Swift.h"

#import "BCOVVideoPlayerManager.h"


@implementation BCOVVideoPlayerManager

RCT_EXPORT_MODULE(BCOVVideoPlayer)

- (UIView *)view
{
    BCOVVideoPlayer *player = [[BCOVVideoPlayer alloc] initWithFrame:UIScreen.mainScreen.bounds];
    player.eventDispatcher = (RCTEventDispatcher *)self.bridge.eventDispatcher;
    return player;
}

- (dispatch_queue_t)methodQueue
{
    return self.bridge.uiManager.methodQueue;
}

RCT_EXPORT_VIEW_PROPERTY(options, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock);
RCT_EXPORT_METHOD(playPause:(nonnull NSNumber *)reactTag isPlaying:(BOOL)isPlaying {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BCOVVideoPlayer *player = (BCOVVideoPlayer *)viewRegistry[reactTag];
        if ([player isKindOfClass:[BCOVVideoPlayer class]])
        {
            [player playPause:isPlaying];
        }
    }];
});

@end
