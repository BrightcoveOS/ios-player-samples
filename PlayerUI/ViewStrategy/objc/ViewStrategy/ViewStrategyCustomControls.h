//
//  ViewStrategyCustomControls.h
//  ViewStrategy
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>


@interface ViewStrategyCustomControls : UIView <BCOVPlaybackSessionConsumer>

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController;

@end
