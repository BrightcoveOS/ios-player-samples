//
//  ViewStrategyCustomControls.h
//  ViewStrategy
//
//  Created by Carlos Ceja.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;


@interface ViewStrategyCustomControls : UIView <BCOVPlaybackSessionConsumer>

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController;

@end
