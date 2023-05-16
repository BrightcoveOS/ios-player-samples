//
//  BaseViewController.h
//  BasicDAIPlayer
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcoveDAI/BrightcoveDAI.h>

#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>


extern NSString * const kViewControllerGoogleDAISourceId;
extern NSString * const kViewControllerGoogleDAIVideoId;
extern NSString * const kViewControllerGoogleDAIAssetKey;


@interface BaseViewController : UIViewController <BCOVPlaybackControllerDelegate, IMALinkOpenerDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) BCOVPlayerSDKManager *manager;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, strong) id<NSObject> notificationReceipt;

- (void)setupPlaybackController;
- (BCOVVideo *)updateVideo:(BCOVVideo *)video;

@end
