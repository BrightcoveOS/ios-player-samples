//
//  ViewStrategyCustomControls.h
//  ViewStrategy
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;
#import <UIKit/UIKit.h>


@interface ViewStrategyCustomControls : UIView <BCOVPlaybackSessionConsumer>

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController;

@end
