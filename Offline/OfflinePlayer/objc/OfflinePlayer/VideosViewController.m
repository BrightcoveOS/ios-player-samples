//
//  VideosViewController.m
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import "VideosViewController.h"
#import "DownloadsViewController.h"
#import "SettingsViewController.h"

// Dynamic Delivery account credentials
// Your account can contain FairPlay-protected HLS videos, or unprotected HLS videos
NSString * const kDynamicDeliveryAccountID = @"5434391461001";
NSString * const kDynamicDeliveryPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
NSString * const kDynamicDeliveryPlaylistRefID = @"brightcove-native-sdk-plist";

// For quick access to this controller from other tabs
VideosViewController *gVideosViewController;

// The Videos View Controller displays a list of HLS videos retrieved
// from a Brightcove Dynamic Delivery account playlist.
// You can tap the download button on a video to begin downloading the video.
@interface VideosViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVOfflineVideoManagerDelegate, UITableViewDataSource, UITableViewDelegate>

// Brightcove-related objects
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVFPSBrightcoveAuthProxy *authProxy;

// View that holds the PlayerUI content where the video and controls are displayed
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

// Keep track of info from the playlist for easy display in the table
@property NSMutableArray<BCOVVideo *> *currentVideos;

// The download queue.
// Videos go into the preload queue first.
// When all preloads are done, videos move to the download queue.
@property NSMutableArray<NSDictionary *> *videoPreloadQueue;
@property NSMutableArray<NSDictionary *> *videoDownloadQueue;

// Keep track of info from the playlist
// for easy display in the table
@property (nonatomic, strong) NSString *currentPlaylistTitle;
@property (nonatomic, strong) NSString *currentPlaylistDescription;
@property (nonatomic, strong) NSMutableDictionary *imageCacheDictionary;

// Table view displaying available videos from playlist, and its refresh control
@property (nonatomic, strong) IBOutlet UITableView *videosTableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end


@implementation VideosViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Become delegate so we can control orientation
    gVideosViewController.tabBarController.delegate = self;

    [self updateStatus];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showWarnings];
}

- (void)setup
{
    [self retrievePlaylist];
    [self createNewPlaybackController];
    [self updateStatus];

    self.videoPreloadQueue = NSMutableArray.array;
    self.videoDownloadQueue = NSMutableArray.array;
}

- (void)runPreloadVideoQueue
{
    NSDictionary *videoDownloadDictionary = self.videoPreloadQueue.firstObject;
    BCOVVideo *video = videoDownloadDictionary[@"video"];
    NSDictionary *parameters = videoDownloadDictionary[@"parameters"];
    
    // Once the preload queue is empty, start the download queue
    if (video == nil)
    {
        [self downloadVideoFromQueue];
        return;
    }
    
    [self.videoPreloadQueue removeObject:videoDownloadDictionary];
    
    // Preloading only applies to FairPlay-protected videos.
    // If there's no FairPlay involved, the video is moved on
    // to the video download queue.
    if (!video.usesFairPlay)
    {
        NSLog(@"Video \"%@\" does not use FairPlay; preloading not necessary", video.properties[@"name"]);
        [self.videoDownloadQueue addObject:videoDownloadDictionary];
        
        NSAssert(NSThread.isMainThread, @"Must update UI on main thread");
        [self.videosTableView reloadData];

        [self runPreloadVideoQueue];
    }
    else
    {
        [BCOVOfflineVideoManager.sharedManager preloadFairPlayLicense:video
                                                           parameters:parameters
         
                                                           completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   
                                                                   if (error == nil)
                                                                   {
                                                                       NSLog(@"Preloaded %@", offlineVideoToken);
                                                                       
                                                                       [self.videoDownloadQueue addObject:videoDownloadDictionary];
                                                                       
                                                                       [self.videosTableView reloadData];
                                                                   }
                                                                   else
                                                                   {
                                                                       // Report any errors
                                                                       BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
                                                                       NSString *alertMessage = error.localizedDescription;
                                                                       NSString *alertTitle = [NSString stringWithFormat:@"Video Preload Error (\"%@\")", video.properties[@"name"]];
                                                                       UIAlertController* alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                                                      message:alertMessage
                                                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                                       UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                             handler:^(UIAlertAction * action) {}];
                                                                       
                                                                       [alert addAction:defaultAction];
                                                                       [self presentViewController:alert animated:YES completion:nil];
                                                                   }
                                                                   
                                                                   [self runPreloadVideoQueue];
                                                                   
                                                               });
                                                               
                                                           }];
    }
}

static BOOL sDownloadInProgress = NO;
- (void)downloadVideoFromQueue
{
    // If we're already downoading, this will be called automatically
    // when the download is done
    if (sDownloadInProgress)
        return;
    
    NSDictionary *videoDownloadDictionary = self.videoDownloadQueue.firstObject;
    BCOVVideo *video = videoDownloadDictionary[@"video"];
    NSDictionary *parameters = videoDownloadDictionary[@"parameters"];

    if (video == nil)
    {
        // done!
        return;
    }
    
    [self.videoDownloadQueue removeObject:videoDownloadDictionary];
    
    sDownloadInProgress = YES;

    // Display all available bitrates
    [BCOVOfflineVideoManager.sharedManager variantBitratesForVideo:(BCOVVideo *)video
                                                        completion:^(NSArray<NSNumber *> *bitrates, NSError *error)
     {

         NSLog(@"Variant Bitrates for video: %@", video.properties[@"name"]);
         for (NSNumber *bitrateNumber in bitrates)
         {
             // Make sure the array contains the correct objects
             if (! [bitrateNumber isKindOfClass :NSNumber.class])
             {
                 NSLog(@"bitrateNumber contains the wrong class: %@", bitrateNumber.class.description);
             }
             
             NSLog(@"\t%d", bitrateNumber.intValue);
         }
     
     }];
    
    [self.offlineVideoManager requestVideoDownload:video
                                        parameters:parameters
                                        completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                
                                                if (error == nil)
                                                {
                                                    // Success! Update our table with the new download status
                                                    [self updateStatus];
                                                }
                                                else
                                                {
                                                    sDownloadInProgress = NO;

                                                    // try again with another video
                                                    [self downloadVideoFromQueue];

                                                    // Report any errors
                                                    BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
                                                    BCOVVideo *videoName = video.properties[@"name"];
                                                    NSString *alertMessage = error.localizedDescription;
                                                    NSString *alertTitle = (videoName != nil ? [NSString stringWithFormat:@"Video Download Error (\"%@\")", videoName] : @"Video Download Error");
                                                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                                   message:alertMessage
                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                          handler:^(UIAlertAction * action) {}];
                                                    
                                                    [alert addAction:defaultAction];
                                                    [self presentViewController:alert animated:YES completion:nil];
                                                }
                                                
                                            });
                                            
                                        }];
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
            NSString *videoID = video.properties[@"id"];
            
            // Find the https URL to our thumbnail
            NSArray *thumbnailSourcesArray = video.properties[@"thumbnail_sources"];
            
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
        long long int bitrate = gSettingsViewController.bitrate;
        [self.offlineVideoManager estimateDownloadSize:video
                                               options:@{
                                                         kBCOVOfflineVideoManagerRequestedBitrateKey: @(bitrate)
                                                         }
                                            completion:^(double megabytes, NSError *error) {
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    
                                                    // Store the estimated size in our dictionary
                                                    // so we don't need to keep recomputing it
                                                    NSString *videoID = video.properties[@"id"];
                                                    
                                                    if (videoID != nil)
                                                    {
                                                        // Use the video's id as the key
                                                        self.estimatedDownloadSizeDictionary[videoID] = @(megabytes);
                                                    }
                                                    
                                                    [self.videosTableView reloadData];
                                                    
                                                });
                                                
                                            }];
        
        NSDictionary *videoDictionary =
        @{
          @"video": video,
          @"state": ( video.canBeDownloaded ? @(eVideoStateDownloadable) : @(eVideoStateOnlineOnly) )
          };
        
        [self.videosTableViewData addObject:videoDictionary.mutableCopy];
    }
    
    [self updateStatusForPlaylist];

    [self.videosTableView reloadData];
}

- (void)retrieveVideoWithAccount:(NSString *)accountID
                         videoID:(NSString *)videoID
                      completion:(void (^)(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error))completionHandler
{
    NSAssert(completionHandler!=nil, @"Completion handler cannot be nil");

    // Retrieve a playlist through the BCOVPlaybackService
    BCOVPlaybackServiceRequestFactory *playbackServiceRequestFactory = [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kDynamicDeliveryAccountID
                                                                                                                          policyKey:kDynamicDeliveryPolicyKey];
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithRequestFactory:playbackServiceRequestFactory];

    [playbackService findVideoWithVideoID:videoID
                               parameters:nil
                               completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error)
     {

     // Pass on to caller
     completionHandler(video, jsonResponse, error);

     }];
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
    
    [playbackService findPlaylistWithReferenceID:kDynamicDeliveryPlaylistRefID
                                      parameters:queryParameters
                                      completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error)
     {

         [self.refreshControl endRefreshing];

         NSLog(@"JSON Response:\n%@", jsonResponse);
         
         if (playlist)
         {
             self.currentVideos = playlist.videos.mutableCopy;
             self.currentPlaylistTitle = playlist.properties[@"name"];
             self.currentPlaylistDescription = playlist.properties[@"description"];

             NSLog(@"Retrieved playlist containing %d videos", (int)self.currentVideos.count);

             [self usePlaylist:self.currentVideos];
         }
         else
         {
             NSLog(@"No playlist for ID %@ was found.", kDynamicDeliveryPlaylistRefID);
         }
         
     }];
}

- (void)downloadAllSecondaryTracksForOfflineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
{
    // This demonstrates the "iOS 11 way" of downloading all secondary tracks
    // for your offline video.
    if (@available(iOS 11.0, *))
    {
        // Get the offline video object
        BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
        
        // Get the path to the locally stored video and make an AVURLAsset out of it
        NSString *offlineVideoPath = offlineVideo.properties[kBCOVOfflineVideoFilePathPropertyKey];
        if (offlineVideoPath == nil)
        {
            NSLog(@"Video path for %@ not found", offlineVideoToken);
            return;
        }
        
        NSURL *offlineVideoPathURL = [NSURL fileURLWithPath:offlineVideoPath];
        
        AVURLAsset *URLAsset = [AVURLAsset assetWithURL:offlineVideoPathURL];
        
        // Get all the available media selections
        NSArray<AVMediaSelection *> *mediaSelections = URLAsset.allMediaSelections;
        
        if (mediaSelections.count > 0)
        {
            // Log the list of media selections that will be downloaded:
            NSLog(@"Found %d media selections in %@", (int)mediaSelections.count, offlineVideoToken);
            for (AVMediaSelection *mediaSelection in mediaSelections)
            {
                NSString *mediaSelectionDescription = [self mediaSelectionDescription:mediaSelection
                                                                             URLAsset:URLAsset];
                
                NSLog(@"\t%@", mediaSelectionDescription);
            }
            
            [BCOVOfflineVideoManager.sharedManager requestMediaSelectionsDownload:mediaSelections
                                                                offlineVideoToken:offlineVideoToken];
        }
        else
        {
            NSLog(@"There are no secondary tracks to download");
        }
    }
    else
    {
        NSLog(@"Secondary tracks can only be downloaded with this method on iOS 11+.");
    }
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

#pragma mark - BCOVOfflineVideoManagerDelegate Methods

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
             downloadTask:(AVAssetDownloadTask *)downloadtask
            didProgressTo:(NSTimeInterval)percent
{
    // This delegate method reports progress for the primary video download
    NSLog(@"Offline download didProgressTo: %0.2f%% for token: %@", (float)percent, offlineVideoToken);
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [self updateStatus];
        [gDownloadsViewController refresh];
        [gDownloadsViewController updateInfoForSelectedDownload];

    });
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
didFinishDownloadWithError:(NSError *)error
{
    // The video has completed downloading

    // On iOS 10, any requested caption tracks will have been downloaded
    // along with the primary video.
    
    // On iOS 11+, after the video has downloaded, you can request that
    // additional tracks be downloaded.
    // In this app, a long press on the downloaded video will present
    // the option to download all extra tracks.
    
    NSLog(@"Download finished with error: %@", error);
    
    sDownloadInProgress = NO;
    
    // Get the next video
    [self downloadVideoFromQueue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateStatus];
        [gDownloadsViewController refresh];
        [gDownloadsViewController updateInfoForSelectedDownload];
        
    });
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
    aggregateDownloadTask:(AVAssetDownloadTask *)downloadtask
            didProgressTo:(NSTimeInterval)progressPercent
        forMediaSelection:(AVMediaSelection *)mediaSelection NS_AVAILABLE_IOS(11_0)
{
    // iOS 11+ only
    // The specific requested media selected option related to this
    // offline video token has progressed to the specified percent
    NSLog(@"aggregateDownloadTask:didProgressTo:%0.2f for token: %@", progressPercent, offlineVideoToken);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateStatus];
        [gDownloadsViewController refresh];
        [gDownloadsViewController updateInfoForSelectedDownload];
        
    });
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
didFinishMediaSelectionDownload:(AVMediaSelection *)mediaSelection NS_AVAILABLE_IOS(11_0)
{
    // iOS 11+ only
    // The specific requested media selected option related to this
    // offline video token has completed downloading
    BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager offlineVideoStatusForToken:offlineVideoToken];
    AVURLAsset *asset = offlineVideoStatus.aggregateDownloadTask.URLAsset;
    NSString *mediaSelectionDescription = [self mediaSelectionDescription:mediaSelection
                                                                 URLAsset:asset];
    NSLog(@"didFinishMediaSelectionDownload:%@ withToken:%@", mediaSelectionDescription, offlineVideoToken);
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
didFinishAggregateDownloadWithError:(NSError *)error NS_AVAILABLE_IOS(11_0)
{
    // iOS 11+ only
    // All requested secondary tracks related to this offline video token
    // have completed downloading
    NSLog(@"didFinishAggregateDownloadWithError:%@ withToken:%@", error, offlineVideoToken);

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateStatus];
        [gDownloadsViewController refresh];
        [gDownloadsViewController updateInfoForSelectedDownload];
        
    });
}

- (void)didDownloadStaticImagesWithOfflineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
{
    // Called when the thumbnail and poster frame downloads
    // for the specified video token are complete
}

- (void)offlineVideoStorageDidChange
{
    [self updateStatus];
    [gDownloadsViewController refresh];
    [gDownloadsViewController updateInfoForSelectedDownload];
}

#pragma mark - Support

- (NSString *)mediaSelectionDescription:(AVMediaSelection *)mediaSelection
                      offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
{
    // Get the offline video object
    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
    
    // Get the path to the locally stored video and make an AVURLAsset out of it
    NSString *offlineVideoPath = offlineVideo.properties[kBCOVOfflineVideoFilePathPropertyKey];
    if (offlineVideoPath == nil)
    {
        return @"MediaSelection(n/a)";
    }

    NSURL *offlineVideoPathURL = [NSURL fileURLWithPath:offlineVideoPath];
    
    AVURLAsset *URLAsset = [AVURLAsset assetWithURL:offlineVideoPathURL];
    
    NSString *description = [self mediaSelectionDescription:mediaSelection
                                                   URLAsset:URLAsset];
    return description;
}

- (NSString *)mediaSelectionDescription:(AVMediaSelection *)mediaSelection
                               URLAsset:(AVURLAsset *)URLAsset
{
    // Return a string description of the specified Media Selection.
    AVMediaSelectionGroup *legibleMediaSelectionGroup = [URLAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionGroup *audibleMediaSelectionGroup = [URLAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    AVMediaSelectionOption *legibleMediaSelectionOption = [mediaSelection selectedMediaOptionInMediaSelectionGroup:legibleMediaSelectionGroup];
    AVMediaSelectionOption *audibleMediaSelectionOption = [mediaSelection selectedMediaOptionInMediaSelectionGroup:audibleMediaSelectionGroup];
    
    NSString *description = [NSString stringWithFormat:@"MediaSelection(obj:%p, legible:%@, audible:%@)",
                             mediaSelection,
                             legibleMediaSelectionOption.displayName ?: @"-",
                             audibleMediaSelectionOption.displayName ?: @"-"];
    return description;
}

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
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Reminder..."
                                                                   message:@"FairPlay videos won't download or display in a simulator."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
#endif
    
    // Account credentials warning
    if (kDynamicDeliveryAccountID.length == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Invalid account information"
                                                                       message:@"Don't forget to enter your account information at the top of VideosViewController.m."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.downloadSizeDictionary = [NSMutableDictionary dictionary];

    NSDictionary *optionsDictionary =
    @{
      kBCOVOfflineVideoManagerAllowsCellularDownloadKey: @(NO),
      kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: @(NO),
      kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: @(NO)
      };
    [BCOVOfflineVideoManager initializeOfflineVideoManagerWithDelegate:self
                                                               options:optionsDictionary];
    self.offlineVideoManager = BCOVOfflineVideoManager.sharedManager;
    gVideosViewController = self;

    NSLog(@"Using Brightcove Native Player SDK version %@", BCOVPlayerSDKManager.version);
    
    self.tabBarController = (UITabBarController*)self.parentViewController;
    
    self.videosTableView.dataSource = self;
    self.videosTableView.delegate = self;
    [self.videosTableView setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];
 
    // Add a refresh control to the table view
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(handleTableRefresh:) forControlEvents:UIControlEventValueChanged];
        
        if (@available (iOS 10.0, *))
        {
            // iOS 10 and later: proper refresh control support
            self.videosTableView.refreshControl = self.refreshControl;
        }
        else
        {
            // iOS 9 and earlier: background view is the refresh control
            self.videosTableView.backgroundView = self.refreshControl;
        }
    }

    [NSNotificationCenter.defaultCenter addObserverForName:kBCOVOfflineVideoManagerAnalyticsStorageFullWarningNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull note) {
                                                    
                                                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Analytics storage is full"
                                                                                                                   message:@"Encourage the app user to go online"
                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                          handler:^(UIAlertAction * action) {}];
                                                    [alert addAction:defaultAction];
                                                    [self presentViewController:alert animated:YES completion:nil];

                                                }];
    
    [self createPlayerView];
    [self setup];
    
    [gDownloadsViewController updateBadge];
}

- (IBAction)handleTableRefresh:(id)sender
{
    [self retrievePlaylist];
}

- (void)updateStatus
{
    NSAssert(NSThread.isMainThread, @"Must update UI on main thread");

    // Refresh the list of downloaded videos from the offline video manager
    self.offlineVideoTokenArray = [self.offlineVideoManager offlineVideoTokens];

    // Update UI with current information
    [gDownloadsViewController updateBadge];
    [self.videosTableView reloadData];
    
    [self updateStatusForPlaylist];
}

// Update the video dictionary array with the current status
// as reported by the offline video manager
- (void)updateStatusForPlaylist
{
    NSArray<BCOVOfflineVideoStatus *> *statusArray = [self.offlineVideoManager offlineVideoStatus];

    // Iterate through all the videos in our videos table,
    // and update the status for each one.
    for (NSMutableDictionary *videoDictionary in self.videosTableViewData)
    {
        BCOVVideo *tableVideo = videoDictionary[@"video"];
        if (tableVideo == nil)
            continue;

        BOOL found = NO;

        for (BCOVOfflineVideoStatus * offlineVideoStatus in statusArray)
        {
            BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoStatus.offlineVideoToken];
            
            // Find the matching local video
            if ([self videosMatchWithVideo1:tableVideo video2:offlineVideo])
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
                        videoDictionary[@"state"] = @(eVideoStateDownloading);
                        break;
                    case BCOVOfflineVideoDownloadStateSuspended:
                    case BCOVOfflineVideoDownloadStateTracksSuspended:
                        videoDictionary[@"state"] = @(eVideoStatePaused);
                        break;
                    case BCOVOfflineVideoDownloadStateCancelled:
                    case BCOVOfflineVideoDownloadStateTracksCancelled:
                        videoDictionary[@"state"] = @(eVideoStateCancelled);
                        break;
                    case BCOVOfflineVideoDownloadStateCompleted:
                    case BCOVOfflineVideoDownloadStateTracksCompleted:
                        videoDictionary[@"state"] = @(eVideoStateDownloaded);
                        break;
                    case BCOVOfflineVideoDownloadStateError:
                    case BCOVOfflineVideoDownloadStateTracksError:
                        videoDictionary[@"state"] = @(eVideoStateDownloadable);
                        break;
                }
            }
        }

        // If the video wasn't found in the status array, mark it as downloadable
        if (!found)
        {
            videoDictionary[@"state"] = @(eVideoStateDownloadable);
        }
    }
}

- (BOOL)videosMatchWithVideo1:(BCOVVideo *)v1 video2:(BCOVVideo *)v2
{
    // Returns YES if the two video objects reference the same video asset.
    // Specifically, they have the same account and same video Id.
    NSString *v1Account = v1.properties[kBCOVVideoPropertyKeyAccountId];
    NSString *v1Id = v1.properties[kBCOVVideoPropertyKeyId];
    NSString *v2Account = v2.properties[kBCOVVideoPropertyKeyAccountId];
    NSString *v2Id = v2.properties[kBCOVVideoPropertyKeyId];

    return ([v1Account isEqualToString:v2Account]
            && [v1Id isEqualToString:v2Id]);
}

// Alert and return YES if the video is already downloaded or in a queue
- (BOOL)videoAlreadyProcessing:(BCOVVideo *)video
{
    BCOVOfflineVideoManager *ovm = BCOVOfflineVideoManager.sharedManager;

    // First check to see if the video is in a preload queue
    // videoPreloadQueue is an array of NSDictionary objects,
    // with a BCOVVideo under each "video" key.
    for (NSDictionary *videoDictionary in self.videoPreloadQueue)
    {
        BCOVVideo *testVideo = videoDictionary[@"video"];
        
        if ([self videosMatchWithVideo1:video video2:testVideo])
        {
            NSString *alertMessage = [NSString stringWithFormat:@"The video \"%@\" is already queued to be preloaded", video.properties[kBCOVVideoPropertyKeyName]];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Video Already in Preload Queue"
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            
            
            return YES;
        }
    }
    
    // First check to see if the video is in a download queue
    // videoDownloadQueue is an array of BCOVVideo objects
    for (NSDictionary *videoDownloadDictionary in self.videoDownloadQueue)
    {
        BCOVVideo *testVideo = videoDownloadDictionary[@"video"];
        if (testVideo == nil)
            continue;

        if ([self videosMatchWithVideo1:video video2:testVideo])
        {
            NSString *alertMessage = [NSString stringWithFormat:@"The video \"%@\" is already queued to be downloaded", video.properties[kBCOVVideoPropertyKeyName]];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Video Already in Download Queue"
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            
            
            return YES;
        }
    }
    
    // Next check to see if the video has already been downloaded
    // or is in the process of downloading
    NSArray<BCOVOfflineVideoToken> *offlineVideoTokens = ovm.offlineVideoTokens;
    
    for (BCOVOfflineVideoToken offlineVideoToken in offlineVideoTokens)
    {
        BCOVVideo *testVideo = [ovm videoObjectFromOfflineVideoToken:offlineVideoToken];
        
        if ([self videosMatchWithVideo1:video video2:testVideo])
        {
            NSString *alertMessage = [NSString stringWithFormat:@"The video \"%@\" is already downloaded (or downloading)", video.properties[kBCOVVideoPropertyKeyName]];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Video Already Downloaded"
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            return YES;
        }
    }
    
    return NO;
}

// Return license parameters as a mutable dictionary in case you want to add more params later
- (NSMutableDictionary *)generateLicenseParameters
{
    NSMutableDictionary *licenseParameters = NSMutableDictionary.dictionary;

    // Generate the license parameters based on the Settings tab
    BOOL isPurchaseLicense = [gSettingsViewController purchaseLicenseType];
    // License details are only needed for FairPlay-protected videos.
    // It's harmless to add it for non-FairPlay videos too.
    
    if (isPurchaseLicense)
    {
        NSLog(@"Requesting Purchase License");
        licenseParameters[kBCOVFairPlayLicensePurchaseKey] = @YES;
    }
    else
    {
        unsigned long long rentalDuration = [gSettingsViewController rentalDuration];
        
        NSLog(@"Requesting Rental License:\n"
              @"rentalDuration: %llu",
              rentalDuration);
        
        licenseParameters[kBCOVFairPlayLicenseRentalDurationKey] = @(rentalDuration);
    }

    return licenseParameters;
}

// Return download parameters as a mutable dictionary in case you want to add more params later
- (NSMutableDictionary *)generateDownloadParameters
{
    NSMutableDictionary *downloadParameters = NSMutableDictionary.dictionary;
    
    // Get base license parameters
    downloadParameters = [self generateLicenseParameters];

    // Add bitrate parameter for the primary download
    long long int bitrate = gSettingsViewController.bitrate;
    
    NSLog(@"Requested bitrate: %lld", bitrate);
    
    downloadParameters[kBCOVOfflineVideoManagerRequestedBitrateKey] = @(bitrate);

    return downloadParameters;
}

- (NSArray *)languagesArrayForAlternativeRenditions:(NSArray<NSDictionary *> *)alternativeRenditionAttributesDictionariesArray
{
    // We want to download all subtitle/audio tracks
    // The methods for dowloading them are different on iOS 10 and iOS 11+.
    
    if (alternativeRenditionAttributesDictionariesArray == nil)
        return nil;
    
    // On iOS 10, we look at the available
    NSLog(@"Alternative Rendition Attributes Dictionaries:\n%@", alternativeRenditionAttributesDictionariesArray);
    
    // Collect all the available subtitle languages in a set to avoid duplicates
    NSMutableSet *languagesSet = NSMutableSet.set;
    for (NSDictionary *alternativeRenditionAttributesDictionary in alternativeRenditionAttributesDictionariesArray)
    {
        NSString *typeString = alternativeRenditionAttributesDictionary[@"TYPE"];
        NSString *languageString = alternativeRenditionAttributesDictionary[@"LANGUAGE"];
        if ([typeString isEqualToString:@"SUBTITLES"] && languageString != nil)
        {
            [languagesSet addObject:languageString];
        }
    }
    
    NSArray *languagesArray = languagesSet.allObjects;
    
    {
        // For debugging: display the languages we found
        NSMutableString *languagesString = NSMutableString.string;
        BOOL first = YES;
        for (NSString *languageString in languagesArray)
        {
            // Add comma before each entry after the first
            if (first)
            {
                first = NO;
            }
            else
            {
                [languagesString appendString:@", "];
            }
            
            [languagesString appendString:languageString];
        }
        
        NSLog(@"Languages to download: %@", languagesString);
    }
    
    return languagesArray;
}

// Handle taps on the download button
- (void)doDownloadButton:(UIButton *)button
{
    // Find the video that was tapped
    int index = (int)button.tag;
    NSDictionary *videoDictionary = self.videosTableViewData[index];
    BCOVVideo *video = videoDictionary[@"video"];

    // See if the video has already been downloaded, or is pending download.
    // This displays an alert if necessary.
    if ([self videoAlreadyProcessing:video])
    {
        return;
    }

    // On iOS 11+, we get the license params,
    // and send the video off for preloading.
    // Additional tracks (subtitles, additional audio tracks)
    // are requested *after* the video is downloaded.
    if (@available(iOS 11.0, *))
    {
        NSMutableDictionary *downloadParameters = [self generateDownloadParameters];

        NSDictionary *videoDownloadDictionary =
        @{
          @"video": video,
          @"parameters": downloadParameters
          };
        
        // On iOS 10.3 and later we can perform video preloading
        [self.videoPreloadQueue addObject:videoDownloadDictionary];
        
        [self runPreloadVideoQueue];
        
        return;
    }

    // On iOS 10, we use Sideband Subtitles.
    // Subtitle tracks to be downloaded are specified up front.
    // To do this we find the alternative rendition attributes,
    // and create a list of languages out of them to pass as as an array.
    
    [BCOVOfflineVideoManager.sharedManager alternativeRenditionAttributesDictionariesForVideo:video
                                                                                   completion:^(NSArray<NSDictionary *> *alternativeRenditionAttributesDictionariesArray, NSError *error)
     {
         // This can call back on a background thread
         dispatch_async(dispatch_get_main_queue(), ^{
             
             if (error != nil)
             {
                 // Report any errors
                 NSString *alertMessage = error.localizedDescription;
                 UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Video Download Error"
                                                                                message:alertMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                 UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {}];
                 
                 [alert addAction:defaultAction];
                 [self presentViewController:alert animated:YES completion:nil];
                 return;
             }
             
             NSMutableDictionary *downloadParameters = [self generateDownloadParameters];

             // Collect array of languages here.
             // We're going to download all languages available in the video.
             NSArray *languagesArray = [self languagesArrayForAlternativeRenditions:alternativeRenditionAttributesDictionariesArray];

             // If any additional subtitle languages were found, let's request them.
             if (languagesArray.count > 0)
             {
                 downloadParameters[kBCOVOfflineVideoManagerSubtitleLanguagesKey] = languagesArray;
             }

             // iOS 10.3 allows us to preload the FairPlay license for each video
             if (@available(iOS 10.3, *))
             {
                 NSDictionary *videoDownloadDictionary =
                 @{
                   @"video": video,
                   @"parameters": downloadParameters
                   };
                 
                 // On iOS 10.3 and later we can perform video preloading.
                 // Preloading the license makes for more reliable downloading
                 // when the app goes to the background.
                 [self.videoPreloadQueue addObject:videoDownloadDictionary];
                 
                 [self runPreloadVideoQueue];
             }
             else
             {
                 // On iOS 10.2 and earlier, just download immediately
                 [self.offlineVideoManager requestVideoDownload:video
                                                     parameters:downloadParameters
                                                     completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {
                                                         
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             
                                                             if (error == nil)
                                                             {
                                                                 // Success! Update our table with the new download status
                                                                 [self updateStatus];
                                                             }
                                                             else
                                                             {
                                                                 // Report any errors
                                                                 NSString *alertMessage = error.localizedDescription;
                                                                 UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Video Download Error"
                                                                                                                                message:alertMessage
                                                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                                                                 UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                       handler:^(UIAlertAction * action) {}];
                                                                 
                                                                 [alert addAction:defaultAction];
                                                                 [self presentViewController:alert animated:YES completion:nil];
                                                             }
                                                             
                                                         });
                                                         
                                                     }];
             }
         });
         
     }];
}

#pragma mark - UITableView methods

// Play the video in this row when selected
- (IBAction)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
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
    int row = (int)indexPath.row;
    NSDictionary *videoDictionary = self.videosTableViewData[row];
    BCOVVideo *video = videoDictionary[@"video"];
    NSString *videoID = video.properties[@"id"];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"video_cell"
                                                            forIndexPath:indexPath];
    cell.textLabel.text = video.properties[@"name"];
    // Use red label to indicate that the video is protected with FairPlay
    cell.textLabel.textColor = (video.usesFairPlay ? [UIColor colorWithRed:0.75 green:0.0 blue:0.0 alpha:1.0] : UIColor.blackColor);
    NSString *detailString = video.properties[@"description"];
    if ((detailString == nil) || (detailString.length == 0))
    {
        detailString = video.properties[@"reference_id"] ?: @"nil";
    }

    // Detail text is two lines consisting of:
    // "duration in seconds / estimated download size)"
    // "reference_id"
    cell.detailTextLabel.numberOfLines = 2;
    NSNumber *durationNumber = video.properties[@"duration"];
    // raw duration is in milliseconds
    int duration = durationNumber.intValue / 1000;
    NSNumber *sizeNumber = self.estimatedDownloadSizeDictionary[videoID];
    double megabytes = sizeNumber.doubleValue;
    NSString *twoLineDetailString = [NSString stringWithFormat:@"%d sec / %0.2f MB\n%@",
                                     duration, megabytes,
                                     detailString];
    cell.detailTextLabel.text = twoLineDetailString;

    // Set up the image view
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.imageView.clipsToBounds = YES;

    // Use cached thumbnail image for display
    {
        UIImage *thumbnailImage = (UIImage *)self.imageCacheDictionary[videoID];
        
        // Use a default image if the cached image is not available
        cell.imageView.image = thumbnailImage ?: [UIImage imageNamed:@"bcov"];
    }

    // Set the state information for the cell.
    VideoCell *videoCell = (VideoCell *)cell;
    
    NSNumber *stateNumber = videoDictionary[@"state"];

    [videoCell setStateImage:(VideoState)stateNumber.intValue];

    // Add action to status button.
    [videoCell.statusButton addTarget:self
                               action:@selector(doDownloadButton:)
                     forControlEvents:UIControlEventTouchUpInside];
    videoCell.statusButton.tag = row;
    
    return cell;
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
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 28;
}

@end

// Custom cell implementation to arrange
// text and images more carefully.
// Also adds a download status image.
@implementation VideoCell : UITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self privateInit];
    }

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self privateInit];
    }

    return self;
}

- (void)privateInit
{
    _statusButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_statusButton];
}

- (void)setStateImage:(VideoState)state
{
    UIImage *newImage = nil;
    switch (state)
    {
        case eVideoStateOnlineOnly: // nothing
        {
            break;
        }
        case eVideoStateDownloadable:
        {
            newImage = [UIImage imageNamed:@"download"];
            break;
        }
        case eVideoStateDownloading:
        {
            newImage = [UIImage imageNamed:@"inprogress"];
            break;
        }
        case eVideoStatePaused:
        {
            newImage = [UIImage imageNamed:@"paused"];
            break;
        }
        case eVideoStateDownloaded:
        {
            newImage = [UIImage imageNamed:@"downloaded"];
            break;
        }
        case eVideoStateCancelled:
        {
            newImage = [UIImage imageNamed:@"cancelled"];
            break;
        }
        case eVideoStateError:
        {
            newImage = [UIImage imageNamed:@"error"];
            break;
        }
    }

    [self.statusButton setImage:newImage forState:UIControlStateNormal];
}

- (void)layoutSubviews
{
    NSAssert(NSThread.isMainThread, @"Must update VideoCell UI on main thread");

    [super layoutSubviews];

    const int cIndicatorImageDimension = 32;
    const int cMargin = 8;
    const int cHalfMargin = cMargin / 2;
    int cellWidth = self.frame.size.width;
    int cellHeight = self.frame.size.height;
    
    // Center image on left side of cell
    int rowHeight = cellHeight;
    int thumbnailHeight = rowHeight - cMargin;
    int thumbnailWidth = thumbnailHeight * 16 / 9;
    self.imageView.frame = CGRectMake(cMargin, cHalfMargin, thumbnailWidth, thumbnailHeight);

    CGRect indicatorImageFrame = self.frame;
    
    // Center indicator image on right
    indicatorImageFrame = CGRectMake(cellWidth - cIndicatorImageDimension - cMargin,
                                     (cellHeight - cIndicatorImageDimension) / 2,
                                     cIndicatorImageDimension,
                                     cIndicatorImageDimension);
    self.statusButton.frame = indicatorImageFrame;
    
    // Stack the label/detail text
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.x = cMargin + thumbnailWidth + cMargin;
    labelFrame.size.width = cellWidth - thumbnailWidth - cIndicatorImageDimension - cMargin * 3;
    self.textLabel.frame = labelFrame;
    
    labelFrame = self.detailTextLabel.frame;
    labelFrame.origin.x = cMargin + thumbnailWidth + cMargin;
    labelFrame.size.width = cellWidth - thumbnailWidth - cIndicatorImageDimension - cMargin * 3;
    self.detailTextLabel.frame = labelFrame;
}

@end
