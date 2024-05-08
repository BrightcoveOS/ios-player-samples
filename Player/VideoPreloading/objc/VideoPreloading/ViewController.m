//
//  ViewController.m
//  VideoPreloading
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//


#import "VideoPreloadManager.h"

#import "ViewController.h"



static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kPlaylistRefId = @"brightcove-native-sdk-plist";

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) VideoPreloadManager *videoPreloadManager;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        options.presentingViewController = self;
        options.automaticControlTypeSelection = YES;

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:nil];

        playerView.delegate = self;

        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];

        playerView;
    });

    self.videoPreloadManager = [[VideoPreloadManager alloc] initWithPlaybackControllerDelegate:self
                                                                                 andPlayerView:self.playerView
                                                                             andShouldAutoPlay:YES];

    [self requestContentFromPlaybackService];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{kBCOVPlaybackServiceConfigurationKeyAssetReferenceID:kPlaylistRefId };
    [self.playbackService findPlaylistWithConfiguration:configuration
                                        queryParameters:nil
                                             completion:^(BCOVPlaylist *playlist,
                                                          NSDictionary *jsonResponse,
                                                          NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (playlist)
        {
#if TARGET_OS_SIMULATOR
            NSPredicate *fairPlayPredicate = [NSPredicate predicateWithFormat:@"self.usesFairPlay == %@", @(NO)];
            strongSelf.videoPreloadManager.videos = [playlist.videos filteredArrayUsingPredicate:fairPlayPredicate];
#else
            strongSelf.videoPreloadManager.videos = playlist.videos;
#endif
        }
        else
        {
            NSLog(@"ViewController - Error retrieving playlist: %@", error.localizedDescription);
        }
    }];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[@"error"];
        // Report any errors that may have occurred with playback.
        NSLog(@"ViewController - Playback error: %@", error.localizedDescription);
    }

    if ([kBCOVPlaybackSessionLifecycleEventEnd isEqualToString:lifecycleEvent.eventType])
    {
        [self.videoPreloadManager currentVideoDidCompletePlayback];
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
             didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"Progress: %0.2f seconds", progress);
    [self.videoPreloadManager preloadNextVideoIfNeccessary:session];
}


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

@end
