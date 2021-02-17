//
//  BaseViewController.h
//  BasicIMAPlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import <UIKit/UIKit.h>

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcoveIMA/BrightcoveIMA.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

extern NSString * const kViewControllerIMAPublisherID;

@interface BaseViewController : UIViewController <BCOVIMAPlaybackSessionDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;

- (void)setupPlaybackController;
- (BCOVVideo *)updateVideo:(BCOVVideo *)video;

@end

