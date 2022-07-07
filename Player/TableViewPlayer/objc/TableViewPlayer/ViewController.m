//
//  ViewController.m
//  TableViewPlayer
//
//  Created by Jeremy Blaker on 6/14/22.
//

#import "ViewController.h"
#import "VideoTableViewCell.h"
#import "PlaybackConfiguration.h"
#import "Notifications.h"

@import BrightcovePlayerSDK;

static NSString * const kAccountID = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kPlaylistId = @"1735168388684004403";

@interface ViewController ()<BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, PlaybackConfiguration *> *playbackConfigurations;
@property (nonatomic, strong) NSArray<BCOVVideo *> *videos;
@property (nonatomic, assign) BOOL isScrolling;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 290;
    
    self.playbackConfigurations = @{}.mutableCopy;
    
    [self requestPlaylist];
}

- (void)requestPlaylist
{
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kPolicyKey];
    
    __weak typeof(self) weakSelf = self;
    [playbackService findPlaylistWithPlaylistID:kPlaylistId parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
       
        if (error)
        {
            NSLog(@"Failed to fetch playlist: %@", error.localizedDescription);
            return;
        }
        
        if (playlist.videos)
        {
            weakSelf.videos = playlist.videos;
            [weakSelf setUpPlaybackControllers];
        }
        
    }];
}

- (void)setUpPlaybackControllers
{
    for (BCOVVideo *video in self.videos)
    {
        NSString *videoId = video.properties[kBCOVVideoPropertyKeyId];
        id<BCOVPlaybackController> playbackController = BCOVPlayerSDKManager.sharedManager.createPlaybackController;

        // Caching the thumbnail images for multiple videos
        // will use up a lot of memory so we'll disable this feature
        playbackController.thumbnailSeekingEnabled = NO;
        playbackController.delegate = self;

        // Optimize buffering by keeping them at low values
        // so the multiple players don't use up too much memory
        // https://github.com/brightcove/brightcove-player-sdk-ios#BufferOptimization
        NSMutableDictionary *options = playbackController.options.mutableCopy;
        options[kBCOVBufferOptimizerMethodKey] = @(BCOVBufferOptimizerMethodDefault);
        options[kBCOVBufferOptimizerMinimumDurationKey] = @(1);
        options[kBCOVBufferOptimizerMaximumDurationKey] = @(5);
        playbackController.options = options;

        PlaybackConfiguration *playbackConfiguration = [PlaybackConfiguration new];
        playbackConfiguration.playbackController = playbackController;

        self.playbackConfigurations[videoId] = playbackConfiguration;
        
        [playbackController setVideos:@[video]];
    }
    
    [self.tableView reloadData];
}

- (void)tableScrollingStopped
{
    // Scrolling stopped, let the active cells know they
    // so they can begin playback
    [[NSNotificationCenter defaultCenter] postNotificationName:ScrollingStoppedNotification object:nil];
    self.isScrolling = YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
    
    BCOVVideo *video = self.videos[indexPath.row];
    NSString *videoId = video.properties[kBCOVVideoPropertyKeyId];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ScrollingStartedNotification object:nil];
    self.isScrolling = YES;
}

#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    session.player.muted = YES;

    NSString *videoId = session.video.properties[kBCOVVideoPropertyKeyId];
    PlaybackConfiguration *playbackConfiguration = self.playbackConfigurations[videoId];
    playbackConfiguration.playbackSession = session;
}

@end
