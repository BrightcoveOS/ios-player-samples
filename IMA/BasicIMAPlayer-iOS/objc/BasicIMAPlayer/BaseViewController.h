//
//  BaseViewController.h
//  BasicIMAPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class BCOVVideo;
@class BCOVPUIPlayerView;
@protocol BCOVPlaybackController;
@protocol BCOVPlaybackControllerDelegate;
@protocol BCOVPUIPlayerViewDelegate;
@protocol BCOVIMAPlaybackSessionDelegate;
@protocol IMALinkOpenerDelegate;


@interface BaseViewController : UIViewController <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVIMAPlaybackSessionDelegate, IMALinkOpenerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, readonly, strong) id<BCOVPlaybackSessionProvider> fps;
@property (nonatomic, readonly, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, readonly, strong) NSArray <IMACompanionAdSlot *> *companionAdSlots;

- (void)setupPlaybackController;
- (BCOVVideo *)updateVideo:(BCOVVideo *)video;

@end
