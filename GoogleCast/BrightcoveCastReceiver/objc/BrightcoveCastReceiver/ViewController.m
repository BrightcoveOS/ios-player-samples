//
//  ViewController.m
//  BrightcoveCastReceiver
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;
#import <GoogleCast/GoogleCast.h>
#import <BrightcoveGoogleCast/BrightcoveGoogleCast.h>

#import "AppDelegate.h"
#import "GCKUICastContainerViewController+BrightcoveCastReceiver.h"

#import "ViewController.h"


static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kPlaylistRefId = @"brightcove-native-sdk-plist";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVGoogleCastManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIView *headerTableView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UILabel *headerLabel;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) BCOVGoogleCastManager *googleCastManager;

@property (nonatomic, strong) NSArray<BCOVVideo *> *videos;

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

    GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:castButton];

    self.videoContainerView.hidden = YES;

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.headerTableView.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.headerLabel = ({
        CGSize size = self.headerTableView.frame.size;
        CGRect frame = CGRectMake(20, 0, size.width - 40, size.height);
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.numberOfLines = 1;
        headerLabel.textAlignment = NSTextAlignmentJustified;
        headerLabel.font = [UIFont systemFontOfSize:16];
        headerLabel.textColor = UIColor.systemGrayColor;

        [self.headerTableView addSubview:headerLabel];

        headerLabel;
    });

    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory =
        [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kAccountId
                                                           policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        options.presentingViewController = ((AppDelegate *)UIApplication.sharedApplication.delegate).castContainerViewController;
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

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                               authorizationProxy:authProxy
                                                                                          upstreamSessionProvider:nil];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:fps
                                                                                                   viewStrategy:nil];

        playbackController.delegate = self;

        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        playbackController.allowsBackgroundAudioPlayback = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    self.googleCastManager =  ({
        BCOVReceiverAppConfig *receiverAppConfig = [BCOVReceiverAppConfig new];
        receiverAppConfig.accountId = kAccountId;
        receiverAppConfig.policyKey = kPolicyKey;
        receiverAppConfig.splashScreen = @"https://solutions.brightcove.com/jblaker/cast-splash.jpg";

        // You can specify a customized player
        // receiverAppConfig.playerUrl = @"https://players.brightcove.net/5434391461001/nVM2434Z1_default/index.min.js";

        // You can use the authToken property for PAS/EPA
        // receiverAppConfig.authToken = @"";

        // You can use the adConfigId property for SSAI
        // Intended to be used alongside the SSAI Plugin for Brightcove Player SDK for iOS
        // receiverAppConfig.adConfigId = @"";

        [[BCOVGoogleCastManager alloc] initForBrightcoveReceiverApp:receiverAppConfig];
    });

    self.googleCastManager.delegate = self;

    [self.playbackController addSessionConsumer:self.googleCastManager];

    [self requestContentFromPlaybackService];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(castDeviceDidChange:)
                                               name:kGCKCastStateDidChangeNotification
                                             object:GCKCastContext.sharedInstance];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)castDeviceDidChange:(NSNotification *)notification
{
    switch (GCKCastContext.sharedInstance.castState) {
        case GCKCastStateNoDevicesAvailable:
            NSLog(@"Cast Status: No Devices Available");
            break;
        case GCKCastStateNotConnected:
            NSLog(@"Cast Status: Not Connected");
            break;
        case GCKCastStateConnecting:
            NSLog(@"Cast Status: Connecting");
            break;
        case GCKCastStateConnected:
            NSLog(@"Cast Status: Connected");
            break;
    }
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ BCOVPlaybackService.ConfigurationKeyAssetReferenceID: kPlaylistRefId };
    [self.playbackService findPlaylistWithConfiguration:configuration
                                        queryParameters:nil
                                             completion:^(BCOVPlaylist *playlist,
                                                          NSDictionary *jsonResponse,
                                                          NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (playlist)
        {
            strongSelf.headerLabel.text = playlist.properties[BCOVPlaylist.PropertiesKeyName] ?: @"BrightcoveCastReceiver";
#if TARGET_OS_SIMULATOR
            NSPredicate *fairPlayPredicate = [NSPredicate predicateWithFormat:@"self.usesFairPlay == %@", @(NO)];
            strongSelf.videos = [playlist.videos filteredArrayUsingPredicate:fairPlayPredicate];
#else
            strongSelf.videos = playlist.videos;
#endif

            [strongSelf.tableView reloadData];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving playlist: %@", error.localizedDescription);
            strongSelf.headerLabel.text = @"BrightcoveCastReceiver";
        }

    }];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
  didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventEnd isEqualToString:lifecycleEvent.eventType])
    {
        self.videoContainerView.hidden = YES;
    }

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


#pragma mark - BCOVGoogleCastManager

- (void)switchedToRemotePlayback
{
    self.videoContainerView.hidden = YES;
}

- (void)switchedToLocalPlayback:(NSTimeInterval)lastKnownStreamPosition
                      withError:(NSError *)error
{
    if (lastKnownStreamPosition > 0)
    {
        [self.playbackController play];
    }

    self.videoContainerView.hidden = NO;

    if (error)
    {
        NSLog(@"Switched to local playback with error: %@", error.localizedDescription);
    }
}

- (void)currentCastedVideoDidComplete
{
    self.videoContainerView.hidden = YES;
}

- (void)castedVideoFailedToPlay
{
    NSLog(@"Cast video failed to play!");
}

- (void)suitableSourceNotFound
{
    NSLog(@"Suitable source for video not found!");
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return  section == 0 ? 1 : self.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell"
                                                                 forIndexPath:indexPath];

    if (indexPath.section == 0)
    {
        videoCell.textLabel.text = @"Play All";
        return videoCell;
    }

    BCOVVideo *video = self.videos[indexPath.row];
    videoCell.textLabel.text = video.properties[BCOVVideo.PropertyKeyName] ?: @"";

    return videoCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.videos.count > 0 ? 2 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.videoContainerView.hidden = GCKCastContext.sharedInstance.castState == GCKCastStateConnected;

    if (indexPath.section == 0)
    {
        [self.playbackController setVideos:self.videos];
        return;
    }

    BCOVVideo *video = self.videos[indexPath.row];
    [self.playbackController setVideos:@[ video ]];
}

@end
