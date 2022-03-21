//
//  BCOVVideoPlayer.h
//  PlayerReactNative
//
//  Created by Carlos Ceja.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>

@class RCTEventDispatcher;


NS_ASSUME_NONNULL_BEGIN

@interface BCOVVideoPlayer : UIView

@property (nonatomic, copy) NSDictionary *options;
@property (nonatomic, copy) RCTDirectEventBlock onReady;
@property (nonatomic, copy) RCTDirectEventBlock onProgress;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithEventDispatcher:(id<RCTEventDispatcherProtocol>)eventDispatcher NS_DESIGNATED_INITIALIZER;
- (void)playPause:(BOOL)isPlaying;

@end

NS_ASSUME_NONNULL_END
