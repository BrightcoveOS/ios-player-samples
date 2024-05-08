//
//  ControlViewStyles.h
//  PlayerUICustomization
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCOVPUIBasicControlView;


@interface ControlViewStyles : NSObject

+ (void)simpleForControlsView:(BCOVPUIBasicControlView *)controlsView;

+ (void)complexForControlsView:(BCOVPUIBasicControlView *)controlsView;

@end
