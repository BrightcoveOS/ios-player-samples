//
//  GoogleCastManager.h
//  BasicCastPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@protocol GoogleCastManagerDelegate <NSObject>

@property (nonatomic, readonly, strong) id<BCOVPlaybackController> _Nullable playbackController;

- (void)switchedToLocalPlayback:(NSTimeInterval)lastKnownStreamPosition
                      withError:(nullable NSError *)error;
- (void)switchedToRemotePlayback;
- (void)castedVideoDidComplete;
- (void)castedVideoFailedToPlay;
- (void)suitableSourceNotFound;

@end


@interface GoogleCastManager : NSObject <BCOVPlaybackSessionConsumer>

@property (nonatomic, weak) id<GoogleCastManagerDelegate> _Nullable delegate;

@end
