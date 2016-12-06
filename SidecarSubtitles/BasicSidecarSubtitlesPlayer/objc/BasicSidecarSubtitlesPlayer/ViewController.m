//
//  ViewController.m
//  BasicSidecarSubtitlesPlayer
//
//  Copyright (c) 2015 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveSidecarSubtitles;

@import MediaPlayer;
@import AVFoundation;
@import AVKit;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) BCOVPlaybackService *service;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;

@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (nonatomic, strong) AVPlayerViewController *playerViewController;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createSidecarSubtitlesPlaybackControllerWithViewStrategy:nil];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    _service = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;

    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:nil controlsView:controlView];
    _playerView.frame = _videoContainer.bounds;
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_videoContainer addSubview:_playerView];

    _playerView.playbackController = _playbackController;

    [self requestContentFromPlaybackService];
}

- (void)requestContentFromPlaybackService
{
    [self.service findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {
                NSArray *textTracks = @[];
                textTracks = [self setupSubtitles];
                NSMutableDictionary *updatedDictionary = [mutableVideo.properties mutableCopy];
                updatedDictionary[kBCOVSSVideoPropertiesKeyTextTracks] = textTracks;
                mutableVideo.properties = updatedDictionary;
            }];
            [self.playbackController setVideos:@[updatedVideo]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }
        
    }];
}

- (NSArray *)setupSubtitles
{
    NSArray *textTracks = @[@{ kBCOVSSTextTracksKeyKind: kBCOVSSTextTracksKindSubtitles,
                               kBCOVSSTextTracksKeyLabel: @"English",
                               kBCOVSSTextTracksKeyDefault: @YES,
                               kBCOVSSTextTracksKeySourceLanguage: @"en",
                               kBCOVSSTextTracksKeySource: @"http://players.brightcove.net/3636334163001/ios_native_player_sdk/vtt/sample.vtt",
                               kBCOVSSTextTracksKeyMIMEType: @"text/vtt"
                               }
                            ];
    return textTracks;
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"ViewController Debug - Received lifecycle event.");
}


#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
