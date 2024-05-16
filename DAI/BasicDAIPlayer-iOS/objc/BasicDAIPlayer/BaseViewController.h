//
//  BaseViewController.h
//  BasicDAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcoveDAI/BrightcoveDAI.h>

#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>


extern NSString * const kGoogleDAISourceId;
extern NSString * const kGoogleDAIVideoId;
extern NSString * const kGoogleDAIAssetKey;


@interface BaseViewController : UIViewController <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVDAIPlaybackSessionDelegate, IMALinkOpenerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, readonly, strong) id<BCOVPlaybackSessionProvider> fps;
@property (nonatomic, readonly, strong) BCOVPUIPlayerView *playerView;

- (void)setupPlaybackController;
- (BCOVVideo *)updateVideo:(BCOVVideo *)video;

@end
