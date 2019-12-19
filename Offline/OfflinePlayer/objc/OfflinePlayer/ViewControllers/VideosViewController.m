//
//  VideosViewController.m
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import "VideosViewController.h"

#import "BCOVVIdeo+Convenience.h"
#import "DownloadManager.h"
#import "DownloadsViewController.h"
#import "InterfaceManager.h"
#import "SettingsAdapter.h"
#import "UIAlertController+Convenience.h"
#import "VideoTableViewCell.h"

// The Videos View Controller displays a list of HLS videos retrieved
// from a Brightcove Dynamic Delivery account playlist.
// You can tap the download button on a video to begin downloading the video.
@interface VideosViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, UITableViewDataSource, UITableViewDelegate, VideoTableViewCellDelegate, DownloadManagerDelegate>

// Brightcove-related objects
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVFPSBrightcoveAuthProxy *authProxy;

// View that holds the PlayerUI content where the video and controls are displayed
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

// Table view displaying available videos from playlist, and its refresh control
@property (nonatomic, weak) IBOutlet UITableView *videosTableView;

// Keep track of info from the playlist for easy display in the table
@property (nonatomic, strong) NSMutableArray<BCOVVideo *> *currentVideos;

// Keep track of info from the playlist
// for easy display in the table
@property (nonatomic, strong) NSString *currentPlaylistTitle;
@property (nonatomic, strong) NSString *currentPlaylistDescription;
@property (nonatomic, strong) NSMutableDictionary *imageCacheDictionary;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end


@implementation VideosViewController

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Become delegate so we can control orientation
    [InterfaceManager.sharedInstance updateTabBarDelegate:self];

    [self updateStatus];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showWarnings];
    
    DownloadManager.sharedInstance.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"Using Brightcove Native Player SDK version %@", BCOVPlayerSDKManager.version);
    
    self.videosTableView.dataSource = self;
    self.videosTableView.delegate = self;
    [self.videosTableView setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];
 
    // Add a refresh control to the table view
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(handleTableRefresh:) forControlEvents:UIControlEventValueChanged];
        
        self.videosTableView.refreshControl = self.refreshControl;
    }

    [NSNotificationCenter.defaultCenter addObserverForName:kBCOVOfflineVideoManagerAnalyticsStorageFullWarningNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull note) {
                                                    
                                                    [UIAlertController showAlertWithTitle:@"Analytics storage is full"
                                                                                  message:@"Encourage the app user to go online"
                                                                              actionTitle:@"OK"
                                                                             inController:self];

                                                }];
    
    [self createPlayerView];
    [self setup];
    
    [InterfaceManager.sharedInstance.downloadsViewController updateBadge];
}

#pragma mark - Misc

- (void)setup
{
    [self.videosTableView registerNib:[UINib nibWithNibName:@"VideoTableViewCell" bundle:nil] forCellReuseIdentifier:@"VideoTableViewCell"];
    self.videosTableView.estimatedRowHeight = 65;
    
    [self retrievePlaylist];
    [self createNewPlaybackController];
    [self updateStatus];
}

- (void)didRemoveVideoFromTable:(nonnull BCOVOfflineVideoToken)brightcoveOfflineToken
{
    // Called from the Downloads tab so that we can update our download status
    [self updateStatus];
}

- (void)usePlaylist:(NSArray *)playlist
{
    // Re-initialize all the containers that store information
    // related to the videos in the current playlist
    self.imageCacheDictionary = [NSMutableDictionary dictionary];
    self.videosTableViewData = [NSMutableArray array];
    self.estimatedDownloadSizeDictionary = [NSMutableDictionary dictionary];
    
    for (BCOVVideo *video in playlist)
    {
        // Async task to get and store thumbnails
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // videoID is the key in the image cache dictionary
            NSString *videoID = video.properties[kBCOVVideoPropertyKeyId];
            
            // Find the https URL to our thumbnail
            NSArray *thumbnailSourcesArray = video.properties[kBCOVVideoPropertyKeyThumbnailSources];
            
            if (thumbnailSourcesArray)
            {
                for (NSDictionary *thumbnailDictionary in thumbnailSourcesArray)
                {
                    NSString *thumbnailURLString = thumbnailDictionary[@"src"];
                    if (thumbnailURLString == nil)
                        return;
                    
                    NSURL *thumbnailURL = [NSURL URLWithString:thumbnailURLString];
                    if ([thumbnailURL.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
                    {
                        NSData *thumbnailImageData = [NSData dataWithContentsOfURL:thumbnailURL];
                        UIImage *thumbnailImage = [UIImage imageWithData:thumbnailImageData];
                        
                        if (thumbnailImage != nil)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                self.imageCacheDictionary[videoID] = thumbnailImage;
                                [self.videosTableView reloadData];
                                
                            });
                        }
                    }
                }
            }
        });
        
        // Estimate download size for each video
        __weak typeof(self) weakSelf = self;
        long long int bitrate = SettingsAdapter.bitrate;
        [DownloadManager.sharedInstance.offlineVideoManager estimateDownloadSize:video
                                               options:@{
                                                         kBCOVOfflineVideoManagerRequestedBitrateKey: @(bitrate)
                                                         }
                                            completion:^(double megabytes, NSError *error) {
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    
                                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                                    
                                                    // Store the estimated size in our dictionary
                                                    // so we don't need to keep recomputing it
                                                    NSString *videoID = video.properties[kBCOVVideoPropertyKeyId];
                                                    
                                                    if (videoID != nil)
                                                    {
                                                        // Use the video's id as the key
                                                        strongSelf.estimatedDownloadSizeDictionary[videoID] = @(megabytes);
                                                    }
                                                    
                                                    [strongSelf.videosTableView reloadData];
                                                    
                                                });
                                                
                                            }];
        
        NSDictionary *videoDictionary =
        @{
          @"video": video,
          @"state": ( video.canBeDownloaded ? @(VideoStateDownloadable) : @(VideoStateOnlineOnly) )
          };
        
        [self.videosTableViewData addObject:videoDictionary.mutableCopy];
    }
    
    [self updateStatusForPlaylist];

    [self.videosTableView reloadData];
}

- (void)retrievePlaylist
{
    [self.refreshControl beginRefreshing];

    NSDictionary *queryParameters = @{
                                      @"limit" : @(100), // make sure we get a lot of videos
                                      @"offset" :@(0)
                                      };

    // Retrieve a playlist through the BCOVPlaybackService
    BCOVPlaybackServiceRequestFactory *playbackServiceRequestFactory = [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kDynamicDeliveryAccountID
                                                                                                                          policyKey:kDynamicDeliveryPolicyKey];
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithRequestFactory:playbackServiceRequestFactory];
    
    __weak typeof(self) weakSelf = self;
    [playbackService findPlaylistWithReferenceID:kDynamicDeliveryPlaylistRefID
                                      parameters:queryParameters
                                      completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;

         [strongSelf.refreshControl endRefreshing];

         //NSLog(@"JSON Response:\n%@", jsonResponse);
         
         if (playlist)
         {
             strongSelf.currentVideos = playlist.videos.mutableCopy;
             strongSelf.currentPlaylistTitle = playlist.properties[kBCOVPlaylistPropertiesKeyName];
             strongSelf.currentPlaylistDescription = playlist.properties[kBCOVPlaylistPropertiesKeyDescription];

             NSLog(@"Retrieved playlist containing %d videos", (int)strongSelf.currentVideos.count);

             [strongSelf usePlaylist:strongSelf.currentVideos];
         }
         else
         {
             NSLog(@"No playlist for ID %@ was found.", kDynamicDeliveryPlaylistRefID);
         }
         
     }];
}

#pragma mark - UITabBarController Delegate Methods

- (UIInterfaceOrientationMask)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - BCOVPlaybackController Delegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError];
        NSLog(@"Error: `%@`", error.userInfo[NSUnderlyingErrorKey]);
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    // This method is called when ready to play a new video
    NSLog(@"Session source details: %@", session.source);
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    // This is where you can track playback progress of offline or online videos
}

#pragma mark - BCOVPUIPlayerViewDelegate Methods

- (void)playerView:(BCOVPUIPlayerView *)playerView willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    // Hide the tab bar when we go full screen
    self.tabBarController.tabBar.hidden = (screenMode == BCOVPUIScreenModeFull);
}

#pragma mark - Support

- (void)createPlayerView
{
    // The player view is the BrightCove PlayerUI with built-in controls.
    // This is where the video will be presented; it's reused for all videos.
    if (self.playerView == nil)
    {
        BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
        options.presentingViewController = self;
        
        BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
        self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil
                                                                        options:options
                                                                   controlsView:controlView ];

        self.playerView.delegate = self;
        [self.videoContainer addSubview:self.playerView];
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                                  [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                                  [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                                  [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                                ]];
        
    }
}

- (void)createNewPlaybackController
{
    if (!self.playbackController)
    {
        NSLog(@"Creating a new playbackController");

        // This app shows how to set up your playback controller for playback of FairPlay-protected videos.
        // The playback controller, as well as the download manager will work with either FairPlay-protected
        // videos, or "clear" videos (no DRM protection).
        BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];

        // Publisher/application IDs not required for Dynamic Delivery
        self.authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                   applicationId:nil];
        
        // You can use the same auth proxy for the offline video manager
        // and the call to create the FairPlay session provider.
        BCOVOfflineVideoManager.sharedManager.authProxy = self.authProxy;
        
        // Create the session provider chain
        BCOVBasicSessionProviderOptions *options = [[BCOVBasicSessionProviderOptions alloc] init];
        options.sourceSelectionPolicy = [BCOVBasicSourceSelectionPolicy sourceSelectionHLSWithScheme:kBCOVSourceURLSchemeHTTPS];
        id<BCOVPlaybackSessionProvider> basicSessionProvider = [sdkManager createBasicSessionProviderWithOptions:options];
        id<BCOVPlaybackSessionProvider> fairPlaySessionProvider = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                                                   authorizationProxy:self.authProxy
                                                                                                              upstreamSessionProvider:basicSessionProvider];
        
        // Create the playback controller
        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:fairPlaySessionProvider
                                                                                                   viewStrategy:nil];

        // Start playing right away (the default value for autoAdvance is NO)
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        // Register for delegate method callbacks
        playbackController.delegate = self;

        // Retain the playback controller
        self.playbackController = playbackController;

        // Associate the playback controller with the player view
        self.playerView.playbackController = playbackController;
    }
}

- (void)showWarnings
{
    // Simulator warning
#if (TARGET_OS_SIMULATOR)
    [UIAlertController showAlertWithTitle:@"Reminder..." message:@"FairPlay videos won't download or display in a simulator." actionTitle:@"OK" inController:self];
#endif
    
    // Account credentials warning
    if (kDynamicDeliveryAccountID.length == 0)
    {
        [UIAlertController showAlertWithTitle:@"Invalid account information" message:@"Don't forget to enter your account information at the top of VideosViewController.m." actionTitle:@"OK" inController:self];
    }
}

- (IBAction)handleTableRefresh:(id)sender
{
    [self retrievePlaylist];
}

- (void)updateStatus
{
    NSAssert(NSThread.isMainThread, @"Must update UI on main thread");

    [DownloadManager.sharedInstance updateOfflineTokens];

    // Update UI with current information
    [InterfaceManager.sharedInstance.downloadsViewController updateBadge];
    [self.videosTableView reloadData];
    
    [self updateStatusForPlaylist];
}

// Update the video dictionary array with the current status
// as reported by the offline video manager
- (void)updateStatusForPlaylist
{
    NSArray<BCOVOfflineVideoStatus *> *statusArray = DownloadManager.sharedInstance.offlineVideoManager.offlineVideoStatus;

    // Iterate through all the videos in our videos table,
    // and update the status for each one.
    for (NSMutableDictionary *videoDictionary in self.videosTableViewData)
    {
        BCOVVideo *tableVideo = videoDictionary[@"video"];
        if (tableVideo == nil)
        {
            continue;
        }

        BOOL found = NO;

        for (BCOVOfflineVideoStatus *offlineVideoStatus in statusArray)
        {
            BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoStatus.offlineVideoToken];
            
            // Find the matching local video
            if ([tableVideo videoMatchesVideo:offlineVideo])
            {
                // Match! Update status for this dictionary.
                found = YES;

                switch (offlineVideoStatus.downloadState)
                {
                    case BCOVOfflineVideoDownloadLicensePreloaded:
                    case BCOVOfflineVideoDownloadStateRequested:
                    case BCOVOfflineVideoDownloadStateTracksRequested:
                    case BCOVOfflineVideoDownloadStateDownloading:
                    case BCOVOfflineVideoDownloadStateTracksDownloading:
                        videoDictionary[@"state"] = @(VideoStateDownloading);
                        break;
                    case BCOVOfflineVideoDownloadStateSuspended:
                    case BCOVOfflineVideoDownloadStateTracksSuspended:
                        videoDictionary[@"state"] = @(VideoStatePaused);
                        break;
                    case BCOVOfflineVideoDownloadStateCancelled:
                    case BCOVOfflineVideoDownloadStateTracksCancelled:
                        videoDictionary[@"state"] = @(VideoStateCancelled);
                        break;
                    case BCOVOfflineVideoDownloadStateCompleted:
                    case BCOVOfflineVideoDownloadStateTracksCompleted:
                        videoDictionary[@"state"] = @(VideoStateDownloaded);
                        break;
                    case BCOVOfflineVideoDownloadStateError:
                    case BCOVOfflineVideoDownloadStateTracksError:
                        videoDictionary[@"state"] = @(VideoStateDownloadable);
                        break;
                }
            }
        }

        // If the video wasn't found in the status array, mark it as downloadable
        if (!found)
        {
            videoDictionary[@"state"] = @(VideoStateDownloadable);
        }
    }
}

#pragma mark - UITableView methods

// Play the video in this row when selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *videoDictionary = self.videosTableViewData[ (int)indexPath.row ];
    BCOVVideo *video = videoDictionary[@"video"];

    if (video != nil)
    {
        [self.playbackController setVideos:@[ video ]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.currentPlaylistTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return self.currentPlaylistDescription;
}

// Populate table with data from videosTableViewData
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:@"VideoTableViewCell" forIndexPath:indexPath];
    
    videoCell.delegate = self;
    
    NSDictionary *videoDictionary = self.videosTableViewData[indexPath.row];
    BCOVVideo *video = videoDictionary[@"video"];
    NSString *videoID = video.properties[kBCOVVideoPropertyKeyId];
    
    NSNumber *sizeNumber = self.estimatedDownloadSizeDictionary[videoID];
    double megabytes = sizeNumber.doubleValue;
    
    UIImage *thumbnailImage = (UIImage *)self.imageCacheDictionary[videoID];
    
    NSNumber *stateNumber = videoDictionary[@"state"];
    
    [videoCell setupWithStreamingVideo:video estimatedDownloadSize:megabytes thumbnailImage:thumbnailImage videoState:stateNumber.intValue];
    
    return videoCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videosTableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 28;
}

#pragma mark - VideoTableViewCellDelegate

- (void)downloadButtonTappedForVideo:(BCOVVideo *)video
{
    [DownloadManager.sharedInstance downloadVideo:video];
}

#pragma mark - DownloadManagerDelegate

- (void)shouldRefreshUI
{
    [self.videosTableView reloadData];
}

- (void)encounteredErrorPreloading:(NSError *)error forVideo:(BCOVVideo *)video
{
    // Report any errors
    NSString *alertMessage = error.localizedDescription;
    NSString *alertTitle = [NSString stringWithFormat:@"Video Preload Error (\"%@\")", video.properties[kBCOVVideoPropertyKeyName]];

    [UIAlertController showAlertWithTitle:alertTitle message:alertMessage actionTitle:@"OK" inController:self];
}

- (void)encounteredErrorDownloading:(NSError *)error forVideo:(BCOVVideo *)video
{
    BCOVVideo *videoName = video.properties[kBCOVVideoPropertyKeyName];
    NSString *alertMessage = error.localizedDescription;
    NSString *alertTitle = (videoName != nil ? [NSString stringWithFormat:@"Video Download Error (\"%@\")", videoName] : @"Video Download Error");
    [UIAlertController showAlertWithTitle:alertTitle message:alertMessage actionTitle:@"OK" inController:self];
}

- (void)videoDidBeginDownloading
{
    [self updateStatus];
}

- (void)videoAlreadyPreloadQueued:(BCOVVideo *)video
{
    NSString *alertMessage = [NSString stringWithFormat:@"The video \"%@\" is already queued to be preloaded", video.properties[kBCOVVideoPropertyKeyName]];
    [UIAlertController showAlertWithTitle:@"Video Already in Preload Queue" message:alertMessage actionTitle:@"OK" inController:self];
}

- (void)videoAlreadyDownloadQueued:(BCOVVideo *)video
{
    NSString *alertMessage = [NSString stringWithFormat:@"The video \"%@\" is already queued to be downloaded", video.properties[kBCOVVideoPropertyKeyName]];
    [UIAlertController showAlertWithTitle:@"Video Already in Download Queue" message:alertMessage actionTitle:@"OK" inController:self];
}

- (void)videoAlreadyDownloaded:(BCOVVideo *)video
{
    NSString *alertMessage = [NSString stringWithFormat:@"The video \"%@\" is already downloaded (or downloading)", video.properties[kBCOVVideoPropertyKeyName]];
    [UIAlertController showAlertWithTitle:@"Video Already Downloaded" message:alertMessage actionTitle:@"OK" inController:self];
}

- (void)videoDidFinishDownloadingWithError:(NSError *)error
{
    [self updateStatus];
    [InterfaceManager.sharedInstance.downloadsViewController refresh];
    [InterfaceManager.sharedInstance.downloadsViewController updateInfoForSelectedDownload];
}

- (void)downloadDidProgressTo:(NSTimeInterval)percent
{
    [self updateStatus];
    [InterfaceManager.sharedInstance.downloadsViewController refresh];
    [InterfaceManager.sharedInstance.downloadsViewController updateInfoForSelectedDownload];
}

- (void)downloadRequestDidComplete:(NSError *)error
{
    if (error == nil)
    {
        // Success! Update our table with the new download status
        [self updateStatus];
    }
    else
    {
        [self encounteredGeneralError:error];
    }
}

- (void)encounteredGeneralError:(NSError *)error
{
    // Report any errors
    NSString *alertMessage = error.localizedDescription;
    [UIAlertController showAlertWithTitle:@"Video Download Error" message:alertMessage actionTitle:@"OK" inController:self];
}

@end

