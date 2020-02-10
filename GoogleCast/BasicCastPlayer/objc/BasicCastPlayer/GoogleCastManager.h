//
//  GoogleCastManager.h
//  BasicCastPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BrightcovePlayerSDK/BCOVPlaybackController.h>

@protocol GoogleCastManagerDelegate<NSObject>

@property (nonatomic, strong, readonly) id<BCOVPlaybackController> _Nullable playbackController;

- (void)switchedToLocalPlayback:(NSTimeInterval)lastKnownStreamPosition withError:(nullable NSError *)error;

- (void)switchedToRemotePlayback;

- (void)castedVideoDidComplete;

- (void)castedVideoFailedToPlay;

- (void)suitableSourceNotFound;

@end

@interface GoogleCastManager : NSObject<BCOVPlaybackSessionConsumer>

@property (nonatomic, weak) id<GoogleCastManagerDelegate> _Nullable delegate;

@end
