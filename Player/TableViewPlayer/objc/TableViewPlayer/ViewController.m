//
//  ViewController.m
//  TableViewPlayer
//
//  Created by Brightcove on 6/14/22.
//

#import "Notifications.h"
#import "PlaybackConfiguration.h"
#import "VideoTableViewCell.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kPlaylistId = @"1735168388684004403";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;

@property (nonatomic, strong) NSMutableDictionary<NSString *, PlaybackConfiguration *> *playbackConfigurations;
@property (nonatomic, strong) NSArray<BCOVVideo *> *videos;
@property (nonatomic, assign) BOOL isScrolling;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 300;

    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playbackConfigurations = @{}.mutableCopy;

    [self requestContentFromPlaybackService];
}

- (void)setVideos:(NSArray<BCOVVideo *> *)videos
{
    _videos = videos;

    for (BCOVVideo *video in videos)
    {
        id<BCOVPlaybackController> playbackController = ({
            BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

            BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc]
                                                     initWithPublisherId:nil
                                                     applicationId:nil];

            id<BCOVPlaybackController> controller = [sdkManager
                                                     createFairPlayPlaybackControllerWithAuthorizationProxy:authProxy];

            controller.delegate = self;

            // Caching the thumbnail images for multiple videos
            // will use up a lot of memory so we'll disable this feature
            controller.thumbnailSeekingEnabled = NO;

            // Optimize buffering by keeping them at low values
            // so the multiple players don't use up too much memory
            // https://github.com/brightcove/brightcove-player-sdk-ios#BufferOptimization
            NSMutableDictionary *options = controller.options.mutableCopy;
            options[kBCOVBufferOptimizerMethodKey] = @(BCOVBufferOptimizerMethodDefault);
            options[kBCOVBufferOptimizerMinimumDurationKey] = @(1);
            options[kBCOVBufferOptimizerMaximumDurationKey] = @(5);
            controller.options = options;

            controller;
        });

        PlaybackConfiguration *playbackConfiguration = [PlaybackConfiguration new];
        playbackConfiguration.playbackController = playbackController;

        NSString *videoId = video.properties[BCOVVideo.PropertyKeyId];
        self.playbackConfigurations[videoId] = playbackConfiguration;

        [playbackController setVideos:@[video]];
    }

    [self.tableView reloadData];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *configuration = @{BCOVPlaybackService.ConfigurationKeyAssetID:kPlaylistId};
    [self.playbackService findPlaylistWithConfiguration:configuration
                                        queryParameters:nil completion:^(BCOVPlaylist *playlist,
                                                                         NSDictionary *jsonResponse,
                                                                         NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (playlist)
        {
#if TARGET_OS_SIMULATOR
            NSPredicate *fairPlayPredicate = [NSPredicate predicateWithFormat:@"self.usesFairPlay == %@", @(NO)];
            strongSelf.videos = [playlist.videos filteredArrayUsingPredicate:fairPlayPredicate];
#else
            strongSelf.videos = playlist.videos;
#endif
        }
        else if (error)
        {
            NSLog(@"ViewController - Error retrieving playlist: %@", error.localizedDescription);
        }
    }];
}

- (void)tableScrollingStopped
{
    // Scrolling stopped, let the active cells know they
    // so they can begin playback
    [NSNotificationCenter.defaultCenter postNotificationName:ScrollingStoppedNotification
                                                      object:nil];
    self.isScrolling = YES;
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    session.player.muted = YES;

    NSString *videoId = session.video.properties[BCOVVideo.PropertyKeyId];
    PlaybackConfiguration *playbackConfiguration = self.playbackConfigurations[videoId];
    playbackConfiguration.playbackSession = session;

    if CMTIME_IS_INDEFINITE(session.player.currentItem.duration)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.properties.%@ != %@", BCOVVideo.PropertyKeyId, videoId];
        NSArray *filtered = [self.videos filteredArrayUsingPredicate:predicate];
        self.videos = filtered;
        [self.playbackConfigurations removeObjectForKey:videoId];
        [self.tableView reloadData];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];

    BCOVVideo *video = self.videos[indexPath.row];
    NSString *videoId = video.properties[BCOVVideo.PropertyKeyId];
    PlaybackConfiguration *playbackConfiguration = self.playbackConfigurations[videoId];

    [cell setUpWithVideo:video playbackConfiguration:playbackConfiguration];

    // If we aren't scrolling when this cell is configured
    // go ahead and play!
    if (!self.isScrolling)
    {
        [playbackConfiguration.playbackController play];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 300;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self tableScrollingStopped];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self tableScrollingStopped];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // The table view has begun being scrolled
    // let the active table cells know so that they
    // can pause their videos.
    [NSNotificationCenter.defaultCenter postNotificationName:ScrollingStartedNotification
                                                      object:nil];
    self.isScrolling = YES;
}

@end
