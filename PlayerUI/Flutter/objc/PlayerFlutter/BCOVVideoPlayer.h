//
//  BCOVVideoPlayer.h
//  PlayerFlutter
//
//  Created by Carlos Ceja.
//

#import <Foundation/Foundation.h>

#import <Flutter/Flutter.h>


NS_ASSUME_NONNULL_BEGIN

@interface BCOVVideoPlayer : NSObject <FlutterPlatformView, FlutterStreamHandler>

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end


@interface BCOVVideoPlayerFactory : NSObject <FlutterPlatformViewFactory>

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar;

@end

NS_ASSUME_NONNULL_END
