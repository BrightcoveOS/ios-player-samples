//
//  VideosViewController.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVVideo+OfflinePlayer.h"
#import "DownloadManager.h"
#import "Notifications.h"
#import "SettingsViewController.h"
#import "UIAlertController+OfflinePlayer.h"
#import "UITabBarController+OfflinePlayer.h"
#import "VideoManager.h"
#import "VideoTableViewCell.h"

#import "VideosViewController.h"


@interface VideosViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, VideoTableViewCellDelegate, UITableViewDataSource, UITableViewDelegate>

// View that holds the PlayerUI content
// where the video and controls are displayed
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

// Table view displaying available videos
// from playlist, and its refresh control
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *headerTableView;
@property (nonatomic, weak) IBOutlet UIView *footerTableView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *footerLabel;

// Brightcove-related objects
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation VideosViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *options = @{
        kBCOVOfflineVideoManagerAllowsCellularDownloadKey: @(NO),
        kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: @(NO),
        kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: @(NO)
    };

    [BCOVOfflineVideoManager initializeOfflineVideoManagerWithDelegate:DownloadManager.shared
                                                               options:options];

    self.refreshControl = ({
        UIRefreshControl *refreshControl = [UIRefreshControl new];
        [refreshControl addTarget:self
                           action:@selector(requestContentFromPlaybackService)
                 forControlEvents:UIControlEventValueChanged];
        refreshControl;
    });

    self.tableView.refreshControl = self.refreshControl;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.headerLabel = ({
        CGSize size = self.headerTableView.frame.size;
        CGRect frame = CGRectMake(20, 0, size.width - 40, size.height);
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.numberOfLines = 1;
        headerLabel.textAlignment = NSTextAlignmentJustified;
        headerLabel.font = [UIFont systemFontOfSize:16];
        headerLabel.textColor = UIColor.systemGrayColor;
        headerLabel.backgroundColor = UIColor.clearColor;
        headerLabel;
    });

    self.headerTableView.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1.0].CGColor;
    self.headerTableView.layer.borderWidth = 0.3f;
    [self.headerTableView addSubview:self.headerLabel];

    self.footerLabel = ({
        CGSize size = self.footerTableView.frame.size;
        CGRect frame = CGRectMake(20, 0, size.width - 40, size.height);
        UILabel *footerLabel = [[UILabel alloc] initWithFrame:frame];
        footerLabel.numberOfLines = 1;
        footerLabel.textAlignment = NSTextAlignmentJustified;
        footerLabel.font = [UIFont systemFontOfSize:14];
        footerLabel.textColor = UIColor.systemGrayColor;
        footerLabel.backgroundColor = UIColor.clearColor;
        footerLabel;
    });

    self.footerTableView.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1.0].CGColor;
    self.footerTableView.layer.borderWidth = 0.3f;
    [self.footerTableView addSubview:self.footerLabel];

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

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy =
        [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                  applicationId:nil];

        // You can use the same auth proxy for the offline video manager
        // and the call to create the FairPlay session provider.
        BCOVOfflineVideoManager.sharedManager.authProxy = authProxy;

        BCOVBasicSessionProviderOptions *bspOptions = [BCOVBasicSessionProviderOptions new];
        bspOptions.sourceSelectionPolicy = [BCOVBasicSourceSelectionPolicy sourceSelectionHLSWithScheme:kBCOVSourceURLSchemeHTTPS];
        id<BCOVPlaybackSessionProvider> bsp = [sdkManager createBasicSessionProviderWithOptions:bspOptions];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                               authorizationProxy:authProxy
                                                                                          upstreamSessionProvider:bsp];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:fps
                                                                                                   viewStrategy:nil];

        playbackController.delegate = self;

        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        playbackController.allowsBackgroundAudioPlayback = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    [self requestContentFromPlaybackService];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(analyticsStorageFullWarningNotificationReceived)
                                               name:kBCOVOfflineVideoManagerAnalyticsStorageFullWarningNotification
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateStatus:)
                                               name:UpdateStatus
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                      object:nil];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    self.tabBarController.tabBar.hidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)analyticsStorageFullWarningNotificationReceived
{
    [UIAlertController showWithTitle:@"Analytics storage is full"
                             message:@"Encourage the app user to go online"];
}

- (void)updateStatus:(NSNotification *)notification
{
    NSAssert(NSThread.isMainThread, @"Must update UI on main thread");

    if (self.isVisible)
    {
        BCOVVideo *video = notification.object;
        if (video)
        {
            NSUInteger index = [VideoManager.shared.videos indexOfObject:video];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                        inSection:0];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            [self.tableView reloadData];
        }
    }

    [self.tabBarController updateBadge];
}

- (void)requestContentFromPlaybackService
{
    [self.refreshControl beginRefreshing];

    NSDictionary *configuration = @{ kBCOVPlaybackServiceConfigurationKeyAssetReferenceID: kPlaylistRefId };

    NSDictionary *queryParams = @{ @"limit": @(100), @"offset": @(0) };

    [VideoManager.shared retrievePlaylistWithConfiguration:configuration
                                           queryParameters:queryParams
                                                completion:^(BCOVPlaylist *playlist,
                                                             NSDictionary *jsonResponse,
                                                             NSError *error) {

        [self.refreshControl endRefreshing];

        if (playlist)
        {
            SettingsViewController *settingViewController = self.tabBarController.settingsViewController;
            [VideoManager.shared usePlaylist:playlist.videos
                                 withBitrate:settingViewController.bitrate];

            self.headerLabel.text = playlist.properties[kBCOVPlaylistPropertiesKeyName] ?: @"Offline Player";
            self.footerLabel.text = [NSString stringWithFormat:@"%lu %@",
                                           playlist.count,
                                           (playlist.count != 1 ? @"Videos" : @"Video")];
        }
        else
        {
            NSLog(@"No playlist for Id \"%@\" was found.", @"");

            self.headerLabel.text = @"Offline Player";
            self.footerLabel.text = @"0 Videos";
        }
    }];

}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");

    // This method is called when ready to play a new video
    NSLog(@"Session source details: %@", session.source);
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
  didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[@"error"];
        // Report any errors that may have occurred with playback.
        NSLog(@"ViewController - Playback error: %@", error.localizedDescription);
    }
}


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

#pragma mark - VideoTableViewCellDelegate

- (void)performDownloadForVideo:(BCOVVideo *)video
{
    [DownloadManager.shared doDownloadForVideo:video];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return VideoManager.shared.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:@"VideoTableViewCell"
                                                                    forIndexPath:indexPath];

    BCOVVideo *video = VideoManager.shared.videos[indexPath.row];
    [videoCell setupWithVideo:video
                  andDelegate:self];

    return videoCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];

    BCOVVideo *video = VideoManager.shared.videos[indexPath.row];
    if (!(TARGET_OS_SIMULATOR && video.usesFairPlay))
    {
        [self.playbackController setVideos:@[ video ]];
    }
    else
    {
        [UIAlertController showWithTitle:@"FairPlay Warning"
                                 message:@"FairPlay only works on actual iOS devices.\n\nYou will not be able to view any FairPlay content in the iOS simulator."];
    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

@end
