//
//  DownloadsViewController.m
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import "DownloadsViewController.h"

#import "DownloadManager.h"
#import "InterfaceManager.h"
#import "UIAlertController+Convenience.h"
#import "VideoTableViewCell.h"
#import "VideosViewController.h"

@import BrightcovePlayerSDK;

// The Downloads View Controller displays a list of HLS videos that have been
// downloaded, including videos that are "preloaded", meaning their FairPlay
// licenses have been acquired, and the video content is yet to be downloaded.
//
// You can tap on a video to select it, and thus display information about it.
//
// After selecting it, tap "play" to play the video.
//
// Long-press on a video to download its secondary audio tracks (iOS 11+)
//
// Slide to delete a video.
//
// Tap "More…" to log information about the current video, renew the FairPlay
// license, or delete the video.
//
@interface DownloadsViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *downloadProgressView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *moreButton;
@property (nonatomic, weak) IBOutlet UIButton *pauseButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UITableView *downloadsTableView;
@property (nonatomic, weak) IBOutlet UIImageView *posterImageView;
@property (nonatomic, weak) IBOutlet UILabel *infoLabel;
@property (nonatomic, weak) IBOutlet UILabel *noVideoSelectedLabel;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) UILabel *freeSpaceLabel;
@property (nonatomic, strong) NSTimer *freeSpaceTimer;

// The offline video token of the video selected in the table
@property (nonatomic, strong) BCOVOfflineVideoToken selectedOfflineVideoToken;

// The offline video token playing in the video view
@property (nonatomic, strong) BCOVOfflineVideoToken currentlyPlayingOfflineVideoToken;

@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVFPSBrightcoveAuthProxy *authProxy;
@property (nonatomic, strong) NSDate *sessionStartTime;

// Keeps track of all the final download sizes using the offline video token as a key
@property (nonatomic, strong) NSMutableDictionary *downloadSizeDictionary;

@end

@implementation DownloadsViewController


// Utility for finding the size of a directory in our application folder
static unsigned long long int directorySize(NSString *folderPath)
{
    if (folderPath == nil)
    {
        return 0;
    }
    
    unsigned long long int fileSize = 0;
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    
    for (NSString *fileName in filesArray)
    {
        NSDictionary *fileDictionary =
        [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

#pragma mark Initialization method

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Become delegate so we can control orientation
    [InterfaceManager.sharedInstance updateTabBarDelegate:self];

    [self.downloadsTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.downloadsTableView registerNib:[UINib nibWithNibName:@"VideoTableViewCell" bundle:nil] forCellReuseIdentifier:@"VideoTableViewCell"];
    self.downloadsTableView.estimatedRowHeight = 65;

    self.downloadsTableView.dataSource = self;
    self.downloadsTableView.delegate = self;
    [self.downloadsTableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self createTableFooter];
    [self updateInfoForSelectedDownload];
    
    [self createPlayerView];

    {
        // Long press on a downloaded video gives the option of downloading all tracks (iOS 11+ only)
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 1.0; //seconds
        longPress.delegate = self;
        [self.downloadsTableView addGestureRecognizer:longPress];
    }

    [self setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self freeSpaceUpdate:nil];
    self.freeSpaceTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                           target:self
                                                         selector:@selector(freeSpaceUpdate:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.freeSpaceTimer invalidate];
    self.freeSpaceTimer = nil;
}

#pragma mark - Misc

- (void)setup
{
    self.downloadSizeDictionary = @{}.mutableCopy;
    
    // Add actions to our UI elements
    [self.playButton addTarget:self
                        action:@selector(doPlayHideButton:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.moreButton addTarget:self
                          action:@selector(doMoreButton:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton addTarget:self
                        action:@selector(doPauseResumeButton:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self
                        action:@selector(doCancelButton:)
              forControlEvents:UIControlEventTouchUpInside];
}

- (void)createPlayerView
{
    // The player view is the Brightcove PlayerUI with built-in controls.
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
        self.videoContainer.alpha = 0.0;
    }
}

- (void)createNewPlaybackController
{
    if (!self.playbackController)
    {
        NSLog(@"Creating a new playbackController");
        
        BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
        
        self.authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil applicationId:nil];
        
        id<BCOVPlaybackSessionProvider> psp = [sdkManager createBasicSessionProviderWithOptions:nil];
        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:self.authProxy
                                                                                      upstreamSessionProvider:psp];
        
        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:fps viewStrategy:nil];
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        playbackController.delegate = self;
        self.playbackController = playbackController;
        self.playerView.playbackController = playbackController;
    }
}

- (IBAction)doPlayHideButton:(id)sender
{
    if (self.playbackController == nil)
    {
        BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];
        
        if (video == nil)
        {
            NSLog(@"Could not find video for token %@", self.selectedOfflineVideoToken);
            return;
        }
        
        self.videoContainer.alpha = 1.0;
        
        [self createNewPlaybackController];
        [self.playbackController setVideos:@[ video ]];
        
        [self.playButton setTitle:@"Hide" forState:UIControlStateNormal];
        self.currentlyPlayingOfflineVideoToken = self.selectedOfflineVideoToken;
    }
    else
    {
        // Hiding
        self.playbackController = nil;
        self.videoContainer.alpha = 0.0;

        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        
        self.currentlyPlayingOfflineVideoToken = nil;
    }
}

- (IBAction)doMoreButton:(UIButton *)button
{
    BCOVOfflineVideoToken offlineVideoToken = self.selectedOfflineVideoToken;
    if (offlineVideoToken.length == 0)
    {
        NSLog(@"No video was selected");
        
        [UIAlertController showAlertWithTitle:@"More Options" message:@"No video was selected" actionTitle:@"Cancel" inController:self];
        return;
    }
    
    BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
    NSString *videoName = video.properties[kBCOVVideoPropertyKeyName] ?: @"unknown";
    NSString *message = [NSString stringWithFormat:@"Additional Options for offline video \"%@\"", videoName];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"More Options"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                           handler:nil];
    
    UIAlertAction *logStatusAction =
    [UIAlertAction actionWithTitle:@"Log Status" style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) { [self logStatus]; }];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *renewLicenseAction =
    [UIAlertAction actionWithTitle:@"Renew License" style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               
                               BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];

                               // Get account and video id from offline video so we can request it againBCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
                               NSString *accountID = video.properties[kBCOVVideoPropertyKeyAccountId];
                               NSString *videoID = video.properties[kBCOVVideoPropertyKeyId];

                               NSDictionary *licenseParameters = [DownloadManager.sharedInstance generateLicenseParameters];
                               
                               // Get updated video object to pass to renewal method
                               [DownloadManager.sharedInstance retrieveVideoWithAccount:accountID
                                                                       videoID:videoID
                                                                    completion:^(BCOVVideo *newVideo, NSDictionary *jsonResponse, NSError *error)
                                {
                                if (error != nil)
                                    {
                                    NSLog(@"Could not retrieve new video during FairPlay license renewal. Error: %@", error);
                                    }
                                else
                                    {
                                    [BCOVOfflineVideoManager.sharedManager
                                     renewFairPlayLicense:offlineVideoToken
                                     video:newVideo
                                     parameters:licenseParameters
                                     completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {

                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                        
                                         NSLog(@"FairPlay license renewal completed with error: %@", error);

                                         // Show the new license
                                         dispatch_async(dispatch_get_main_queue(), ^{

                                             [strongSelf updateInfoForSelectedDownload];

                                         });

                                     }];
                                    }

                                }];
                           }];
    
    UIAlertAction *deleteVideoAction =
    [UIAlertAction actionWithTitle:@"Delete Offline Video" style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               
                               // Confirm that the user meant to delete this video
                               NSString *videoName = video.properties[kBCOVVideoPropertyKeyName] ?: @"unknown";
                               NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete the offline video \"%@\"", videoName];
                               UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Offline Video"
                                                                                              message:message
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                               
                               UIAlertAction *cancelAction =
                               [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                      handler:nil];
                               
                               UIAlertAction *deleteVideoAction =
                               [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                      
                                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                                          [strongSelf deleteOfflineVideo:offlineVideoToken];

                                                      }];

                               [alert addAction:cancelAction];
                               [alert addAction:deleteVideoAction];
                               
                               __strong typeof(weakSelf) strongSelf = weakSelf;
                               [strongSelf presentViewController:alert animated:YES completion:nil];

                           }];
    
    // Buttons appear in the order they are added here
    [alert addAction:logStatusAction];
    if (video.usesFairPlay)
    {
        [alert addAction:renewLicenseAction];
    }
    [alert addAction:deleteVideoAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteOfflineVideo:(BCOVOfflineVideoToken)offlineVideoToken
{
    // Delete the selected offline video

    // Delete from storage through the offline video mananger
    [DownloadManager.sharedInstance.offlineVideoManager deleteOfflineVideo:offlineVideoToken];
    
    // Report deletion so that the video page can update download status
    [InterfaceManager.sharedInstance.videosViewController didRemoveVideoFromTable:offlineVideoToken];
    
    // Remove from our local list of video tokens
    [DownloadManager.sharedInstance removeOfflineToken:offlineVideoToken];
    
    if (self.currentlyPlayingOfflineVideoToken != nil
        && [self.currentlyPlayingOfflineVideoToken isEqualToString:offlineVideoToken])
    {
        // Hide this video if it was playing
        [self doPlayHideButton:nil];
    }
    
    // Remove poster image:
    self.posterImageView.image = nil;
    
    // Update text in info panel
    [self updateInfoForSelectedDownload];
    
    [InterfaceManager.sharedInstance.videosViewController updateStatus];
    [self refresh];
}

- (void)logStatus
{
    // Log a variety of information to the debug console
    // about the currently selected offline video token.
    
    BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];

    if (video == nil)
    {
        NSLog(@"Could not find video for token %@", self.selectedOfflineVideoToken);
        return;
    }
    
    NSLog(@"Video Properties:\n%@", video.properties);
    
    NSNumber *sidebandCaptionsValue = video.properties[kBCOVOfflineVideoUsesSidebandSubtitleKey];
    if (sidebandCaptionsValue.boolValue == YES)
    {
        NSArray<NSString *> *sidebandLanguages = video.properties[kBCOVOfflineVideoManagerSubtitleLanguagesKey];
        
        NSMutableString *sidebandLanguagesString = [NSMutableString stringWithString:@""];
        for (NSString *language in sidebandLanguages)
        {
            [sidebandLanguagesString appendString:language];
            [sidebandLanguagesString appendString:@", "];
        }
        
        int stringLength = (int)sidebandLanguagesString.length;
        if (stringLength >= 2)
        {
            [sidebandLanguagesString substringToIndex:stringLength];
        }
        
        NSLog(@"Video uses sideband subtitles with languages: %@", sidebandLanguagesString);
    }
}

- (IBAction)doPauseResumeButton:(id)sender
{
    // Pause or resume based on the current state of the download
    BCOVOfflineVideoManager *sharedManager = BCOVOfflineVideoManager.sharedManager;

    BCOVOfflineVideoStatus *offlineVideoStatus = [sharedManager offlineVideoStatusForToken:self.selectedOfflineVideoToken];
    
    switch (offlineVideoStatus.downloadState)
    {
        case BCOVOfflineVideoDownloadLicensePreloaded:
        case BCOVOfflineVideoDownloadStateRequested:
        case BCOVOfflineVideoDownloadStateTracksRequested:
            break;

        case BCOVOfflineVideoDownloadStateDownloading:
        case BCOVOfflineVideoDownloadStateTracksDownloading:
            [sharedManager pauseVideoDownload:self.selectedOfflineVideoToken];
            [self.pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
            break;

        case BCOVOfflineVideoDownloadStateSuspended:
        case BCOVOfflineVideoDownloadStateTracksSuspended:
            [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
            [sharedManager resumeVideoDownload:self.selectedOfflineVideoToken];
            break;

        case BCOVOfflineVideoDownloadStateCancelled:
        case BCOVOfflineVideoDownloadStateTracksCancelled:
        case BCOVOfflineVideoDownloadStateCompleted:
        case BCOVOfflineVideoDownloadStateTracksCompleted:
        case BCOVOfflineVideoDownloadStateError:
        case BCOVOfflineVideoDownloadStateTracksError:
            break;
    }
}

- (IBAction)doCancelButton:(id)sender
{
    if (@available(iOS 11.2, *))
    {
        // iOS 11.2+: cancel normally
        [self cancelVideoDownload];
    }
    else
    {
        if (@available(iOS 11.0, *))
        {
            // iOS 11.0 and 11.1: work around iOS download manager bugs
            [self forceStopAllDownloadTasks];
        }
        else
        {
            // iOS 10.x: cancel normally
            [self cancelVideoDownload];
        }
    }
}

- (void)forceStopAllDownloadTasks
{
    // iOS 11.0 and 11.1 have a bug in which some downloads cannot be stopped using normal methods.
    // As a workaround, you can call "forceStopAllDownloadTasks" to cancel all the video downloads
    // that are still in progress.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Stop All Downloads"
                                                                   message:@"Do you want to stop all the downloads in progress?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Stop All" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              
                                                              [BCOVOfflineVideoManager.sharedManager forceStopAllDownloadTasks];
                                                              
                                                          }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)cancelVideoDownload
{
    BCOVOfflineVideoManager *sharedManager = BCOVOfflineVideoManager.sharedManager;
    
    BCOVOfflineVideoStatus *offlineVideoStatus = [sharedManager offlineVideoStatusForToken:self.selectedOfflineVideoToken];
    
    switch (offlineVideoStatus.downloadState)
    {
        case BCOVOfflineVideoDownloadStateRequested:
        case BCOVOfflineVideoDownloadStateTracksRequested:
        case BCOVOfflineVideoDownloadStateDownloading:
        case BCOVOfflineVideoDownloadStateTracksDownloading:
        case BCOVOfflineVideoDownloadStateSuspended:
        case BCOVOfflineVideoDownloadStateTracksSuspended:
            [sharedManager cancelVideoDownload:self.selectedOfflineVideoToken];
            break;
            
        case BCOVOfflineVideoDownloadLicensePreloaded:
        case BCOVOfflineVideoDownloadStateCancelled:
        case BCOVOfflineVideoDownloadStateTracksCancelled:
        case BCOVOfflineVideoDownloadStateCompleted:
        case BCOVOfflineVideoDownloadStateTracksCompleted:
        case BCOVOfflineVideoDownloadStateError:
        case BCOVOfflineVideoDownloadStateTracksError:
            break;
    }
}

- (void)refresh
{
    [self.downloadsTableView reloadData];
}

// Set a number on the "Downloads" tab icon
- (void)updateBadge
{
    NSArray<BCOVOfflineVideoStatus *> *statusArray = BCOVOfflineVideoManager.sharedManager.offlineVideoStatus;

    int downloadingCount = 0;

    for (BCOVOfflineVideoStatus *offlineVideoStatus in statusArray)
    {
        if (offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadLicensePreloaded
            || offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateDownloading
            || offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateRequested)
        {
            downloadingCount ++;
        }
    }

    NSString *badgeString;
    if (downloadingCount > 0)
    {
        badgeString = [NSString stringWithFormat:@"%i", downloadingCount];
    }

    [InterfaceManager.sharedInstance updateDownloadsTabBadgeValue:badgeString];
}

- (void)freeSpaceUpdate:(NSTimer *)timer
{
    const double cMB = (1000.0 * 1000.0);
    const double cGB = (cMB * 1000.0);
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfFileSystemForPath:@"/var" error:nil];
    
    NSNumber *freeSizeNumber = attributes[NSFileSystemFreeSize];
    NSNumber *fileSystemSizeNumber = attributes[NSFileSystemSize];
    
    // 1234567.890 -> @"1,234,567.9"
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 1;
    formatter.maximumFractionDigits = 1;
    
    NSString *freeSpaceString = [NSString stringWithFormat:@"Free: %@ MB of %@ GB",
                                 [formatter stringFromNumber:[NSNumber numberWithDouble:freeSizeNumber.doubleValue / cMB]],
                                 [formatter stringFromNumber:[NSNumber numberWithDouble:fileSystemSizeNumber.doubleValue / cGB]]];

    self.freeSpaceLabel.textColor = [UIColor blackColor];
    if (freeSizeNumber.doubleValue / cMB < 500)
    {
        self.freeSpaceLabel.textColor = [UIColor orangeColor];
    }
    if (freeSizeNumber.doubleValue / cMB < 100)
    {
        self.freeSpaceLabel.textColor = [UIColor redColor];
    }
    
    self.freeSpaceLabel.text = freeSpaceString;
    self.freeSpaceLabel.frame = CGRectMake(0, 0, self.downloadsTableView.frame.size.width, 28);

    // Check for downloads in progress as well and update the badge on the Downloads icon
    [self updateBadge];
}

- (void)createTableFooter
{
    // Create the view where we'll show the free space available on the device
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 28)];
    footerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.freeSpaceLabel = [[UILabel alloc] init];
    self.freeSpaceLabel.frame = CGRectMake(0, 0, 320, 28);
    self.freeSpaceLabel.numberOfLines = 1;
    [self.freeSpaceLabel setText:@"Free:"];
    self.freeSpaceLabel.textAlignment = NSTextAlignmentCenter;
    self.freeSpaceLabel.font = [UIFont boldSystemFontOfSize:14];
    self.freeSpaceLabel.textColor = [UIColor blackColor];
    self.freeSpaceLabel.backgroundColor = [UIColor clearColor];
    
    [footerView addSubview:self.freeSpaceLabel];

    self.downloadsTableView.tableFooterView = footerView;
}

- (void)cleanUpSelectedVideoInfo
{
    self.infoLabel.text = nil;
    self.noVideoSelectedLabel.hidden = NO;

    [self.pauseButton setTitle:@"--" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"--" forState:UIControlStateNormal];

    self.playButton.enabled = NO;
    self.moreButton.enabled = NO;
    self.pauseButton.enabled = NO;
    self.cancelButton.enabled = NO;
}

- (void)updateInfoForSelectedDownload
{
    if (self.selectedOfflineVideoToken == nil)
    {
        [self cleanUpSelectedVideoInfo];
        return;
    }
    
    BCOVOfflineVideoStatus *offlineVideoStatus = [DownloadManager.sharedInstance.offlineVideoManager offlineVideoStatusForToken:self.selectedOfflineVideoToken];
    
    if (offlineVideoStatus == nil)
    {
        [self cleanUpSelectedVideoInfo];
        return;
    }
    
    BCOVVideo *video = [DownloadManager.sharedInstance.offlineVideoManager videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];
    
    // Make sure it's a valid video (in case we are updating during a video deletion)
    if (video.properties[kBCOVOfflineVideoTokenPropertyKey] == nil)
    {
        [self cleanUpSelectedVideoInfo];
        return;
    }

    NSString *videoID = video.properties[kBCOVVideoPropertyKeyId];
    NSNumber *sizeNumber = InterfaceManager.sharedInstance.videosViewController.estimatedDownloadSizeDictionary[videoID];
    double megabytes = sizeNumber.doubleValue;
    
    NSNumber *startTimeNumber = video.properties[kBCOVOfflineVideoDownloadStartTimePropertyKey];
    NSTimeInterval startTime = startTimeNumber.doubleValue;
    NSNumber *endTimeNumber = video.properties[kBCOVOfflineVideoDownloadEndTimePropertyKey];
    NSTimeInterval endTime = endTimeNumber.doubleValue;
    NSTimeInterval totalDownloadTime = (endTime - startTime);
    NSTimeInterval currentTime = NSDate.date.timeIntervalSinceReferenceDate;
    
    NSString *licenseText =
    ({
        NSString *text = @"unknown license";
        NSNumber *purchaseNumber = video.properties[kBCOVFairPlayLicensePurchaseKey];
        NSNumber *absoluteExpirationNumber = video.properties[kBCOVOfflineVideoLicenseAbsoluteExpirationTimePropertyKey];
        
        do
        {
            if (!video.usesFairPlay)
            {
                text = @"clear";
                break;
            }
            
            if ((purchaseNumber != nil) && (purchaseNumber.boolValue == YES))
            {
                text = @"purchase";
                break;
            }
            
            if (absoluteExpirationNumber != nil)
            {
                NSTimeInterval absoluteExpirationTime = absoluteExpirationNumber.doubleValue;
                NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceReferenceDate:absoluteExpirationTime];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
                dateFormatter.timeStyle = NSDateFormatterShortStyle;
                text = [NSString stringWithFormat:@"rental (expires %@)",
                        [dateFormatter stringFromDate:expirationDate]];
                
                break;
            }
            else
            {
                NSNumber *rentalDurationNumber = video.properties[kBCOVFairPlayLicenseRentalDurationKey];
                
                if (rentalDurationNumber != nil)
                {
                    double rentalDuration = rentalDurationNumber.doubleValue;
                    NSDate *startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
                    NSDate *expirationDate = [startDate dateByAddingTimeInterval:rentalDuration];
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
                    dateFormatter.timeStyle = NSDateFormatterShortStyle;
                    text = [NSString stringWithFormat:@"rental (expires %@)",
                            [dateFormatter stringFromDate:expirationDate]];

                    break;
                }
            }
        
        } while (false);
        
        text;
    });
    
    double megabytesPerSecond;
    NSString *downloadState;
    
    switch (offlineVideoStatus.downloadState)
    {
        case BCOVOfflineVideoDownloadLicensePreloaded:
            downloadState = @"license preloaded";
            break;
        case BCOVOfflineVideoDownloadStateRequested:
            downloadState = @"download requested";
            break;
        case BCOVOfflineVideoDownloadStateDownloading:
        {
            megabytesPerSecond = ((megabytes * offlineVideoStatus.downloadPercent / 100.0) / (currentTime - startTime));
            // use kbps if the measurement gets too small
            if (megabytesPerSecond < 0.5)
            {
                downloadState = [NSString stringWithFormat:@"downloading (%0.1f%% @ %0.1f KB/s)", offlineVideoStatus.downloadPercent, megabytesPerSecond * 1000.0];
            }
            else
            {
                downloadState = [NSString stringWithFormat:@"downloading (%0.1f%% @ %0.1f MB/s)", offlineVideoStatus.downloadPercent, megabytesPerSecond];
            }
            break;
        }
        case BCOVOfflineVideoDownloadStateSuspended:
        {
            downloadState = [NSString stringWithFormat:@"paused (%0.1f%%)", offlineVideoStatus.downloadPercent];
            break;
        }
        case BCOVOfflineVideoDownloadStateCancelled:
            downloadState = @"cancelled";
            break;
        case BCOVOfflineVideoDownloadStateCompleted:
        {
            NSNumber *actualMegabytesNumber = self.downloadSizeDictionary[self.selectedOfflineVideoToken];
            megabytes = actualMegabytesNumber.floatValue;
            megabytesPerSecond = ((megabytes * offlineVideoStatus.downloadPercent / 100.0) / totalDownloadTime);
            NSString *speedString = (megabytesPerSecond < 0.5
                                     ? [NSString stringWithFormat:@"%0.1f KB/s", megabytesPerSecond * 1000.0]
                                     : [NSString stringWithFormat:@"%0.1f MB/s", megabytesPerSecond]);
            NSString *timeString = (totalDownloadTime < 60
                                    ? [NSString stringWithFormat:@"%d secs", (int)(totalDownloadTime)]
                                    : [NSString stringWithFormat:@"%d mins", (int)(totalDownloadTime / 60.0)]);
            downloadState = [NSString stringWithFormat:@"complete (%@ @ %@)", speedString, timeString];
            break;
        }
        case BCOVOfflineVideoDownloadStateError:
            downloadState = [NSString stringWithFormat:@"error %ld (%@)", (long)offlineVideoStatus.error.code, offlineVideoStatus.error.localizedDescription];
            break;

        case BCOVOfflineVideoDownloadStateTracksRequested:
            downloadState = @"tracks download requested";
            break;
        case BCOVOfflineVideoDownloadStateTracksDownloading:
            downloadState = [NSString stringWithFormat:@"tracks downloading (%0.1f%%)", offlineVideoStatus.downloadPercent];
            break;
        case BCOVOfflineVideoDownloadStateTracksSuspended:
            downloadState = [NSString stringWithFormat:@"tracks paused (%0.1f%%)", offlineVideoStatus.downloadPercent];
            break;
        case BCOVOfflineVideoDownloadStateTracksCancelled:
            downloadState = @"tracks download cancelled";
            break;
        case BCOVOfflineVideoDownloadStateTracksCompleted:
        {
            downloadState = [NSString stringWithFormat:@"tracks download complete"];
            break;
        }
        case BCOVOfflineVideoDownloadStateTracksError:
            downloadState = [NSString stringWithFormat:@"tracks download error %ld (%@)", (long)offlineVideoStatus.error.code, offlineVideoStatus.error.localizedDescription];
            break;
    }
    
    NSString *infoText = [NSString stringWithFormat:@"%@\n"
                          @"Status: %@\n"
                          @"License: %@\n",
                          video.properties[kBCOVVideoPropertyKeyName],
                          downloadState,
                          licenseText];
    
    self.infoLabel.text = infoText;
    [self.infoLabel sizeToFit];
    
    self.noVideoSelectedLabel.hidden = YES;
    self.playButton.enabled = YES;
    self.moreButton.enabled = YES;
    self.pauseButton.enabled = YES;
    self.cancelButton.enabled = YES;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    // Long press on a downloaded video gives the option of downloading all tracks.
    // On iOS 11, this is done here, after the main video has been downloaded.
    // In iOS 10, tracks are downloaded along with the main video.
    // Refer to OfflinePlayback.md for details.
    if (@available(iOS 11.0, *))
    {
        switch (longPress.state)
        {
            default:
            case UIGestureRecognizerStatePossible:
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed:
                // nothing to do:
                break;
                
            case UIGestureRecognizerStateBegan:
            {
                // Find the index of the cell that was long-tapped.
                CGPoint p = [longPress locationInView:self.downloadsTableView];
                
                NSIndexPath *indexPath = [self.downloadsTableView indexPathForRowAtPoint:p];
                int index = (int)indexPath.row;
                if (index >= DownloadManager.sharedInstance.offlineVideoTokenArray.count)
                {
                    return;
                }
                
                BCOVOfflineVideoToken offlineVideoToken = DownloadManager.sharedInstance.offlineVideoTokenArray[index];
                BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager offlineVideoStatusForToken:offlineVideoToken];
                
                // Secondary tracks can be downloaded if...
                // The video has completed downloading...
                // or the track downloading resulted in an error...
                // or track downloading was cancelled.
                if ((offlineVideoStatus.downloadState != BCOVOfflineVideoDownloadStateCompleted)
                    && (offlineVideoStatus.downloadState != BCOVOfflineVideoDownloadStateTracksError)
                    && (offlineVideoStatus.downloadState != BCOVOfflineVideoDownloadStateTracksCancelled))
                {
                    // For other cases, show a warning alert and get out.
                    
                    NSString *message;
                    
                    switch (offlineVideoStatus.downloadState)
                    {
                        case BCOVOfflineVideoDownloadStateCompleted:
                            // all good
                            break;
                        case BCOVOfflineVideoDownloadStateTracksCompleted:
                            message = @"Additional tracks have already been downloaded.";
                            break;
                        case BCOVOfflineVideoDownloadStateTracksRequested:
                        case BCOVOfflineVideoDownloadStateTracksDownloading:
                            message = @"Additional tracks are already downloading.";
                            break;
                        default:
                            message = @"Additional tracks can only be downloaded after the video has been successfully downloaded.";
                            break;
                    }
                    
                    [UIAlertController showAlertWithTitle:@"Download Additional Tracks" message:message actionTitle:@"Cancel" inController:self];
                    
                    return;
                }
                
                BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
                NSString *videoName = offlineVideo.properties[kBCOVVideoPropertyKeyName];
                NSString *message = [NSString stringWithFormat:@"Download all additional tracks for the video \"%@\"?", videoName];
                
                NSLog(@"Long press on \"%@\"", videoName);
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download Additional Tracks"
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Download Tracks" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          
                                                                          [InterfaceManager.sharedInstance.videosViewController downloadAllSecondaryTracksForOfflineVideoToken:offlineVideoToken];
                                                                          
                                                                      }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                                     handler:nil];
                
                
                [alert addAction:defaultAction];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
                
                break;
            }
            case UIGestureRecognizerStateChanged:
            case UIGestureRecognizerStateEnded:
                break;
        }
    }
}

#pragma mark - BCOVPlaybackController Delegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError];
        NSLog(@"Error: `%@`", error.userInfo[NSUnderlyingErrorKey]);
        
        if (error.code == kBCOVOfflineVideoManagerErrorCodeExpiredLicense)
        {
            NSString *videoName = session.video.properties[kBCOVVideoPropertyKeyName] ?: @"unknown";
            NSLog(@"License has expired for the video \"%@\"", videoName);

            [UIAlertController showAlertWithTitle:@"License Expired" message:[NSString stringWithFormat:@"The FairPlay license for the video \"%@\" has expired.", videoName] actionTitle:@"OK" inController:self];
        }
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    if (session)
    {
        self.sessionStartTime = NSDate.date;
        NSLog(@"Session source details: %@", session.source);
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"didProgressTo: %f", progress);
    
    if (@available(iOS 11.0, *))
    {
        // No issues with playback on iOS 11
    }
    else
    {
        // iOS 10:
        // This is a workaround in iOS 10.x to fix an Apple bug where the video
        // does not play properly while downloading
        
        // If the seek jumps past 10 in the first 3 seconds, go back to zero.
        // This works around an Apple 10.x bug where playing downloading vidoes
        // seeks to the end of the video
        if (progress > 10.0 && [NSDate.date timeIntervalSinceDate:self.sessionStartTime] < 3.0 && [NSDate.date timeIntervalSinceDate:self.sessionStartTime] > 1.0)
        {
            self.sessionStartTime = nil;
            [controller pause];
            [controller seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
                
                NSLog(@"seek complete");
                [controller play];
                
            }];
        }
    }
}


#pragma mark - UITabBarController Delegate Methods

- (UIInterfaceOrientationMask)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - BCOVPUIPlayerViewDelegate Methods

- (void)playerView:(BCOVPUIPlayerView *)playerView willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    // Use the PlayerUI's delegate method to hide the tab bar controller
    // when we go full screen.
    self.tabBarController.tabBar.hidden = (screenMode == BCOVPUIScreenModeFull);
}

#pragma mark - UITableView delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedOfflineVideoToken = DownloadManager.sharedInstance.offlineVideoTokenArray[indexPath.row];

    // Load poster image into the detail view
    BCOVVideo *video = [DownloadManager.sharedInstance.offlineVideoManager videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];

    UIImage *defaultImage = [UIImage imageNamed:@"bcov"];
    NSString *posterPathString = video.properties[kBCOVOfflineVideoPosterFilePathPropertyKey];
    UIImage *posterImage = [UIImage imageWithContentsOfFile:posterPathString];
    
    self.posterImageView.image = posterImage ?: defaultImage;
    self.posterImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.posterImageView.clipsToBounds = YES;

    [self updateInfoForSelectedDownload];

    // Update the Pause/Resume button title
    BCOVOfflineVideoStatus *offlineVideoStatus = [DownloadManager.sharedInstance.offlineVideoManager offlineVideoStatusForToken:self.selectedOfflineVideoToken];
    
    switch (offlineVideoStatus.downloadState)
    {
        case BCOVOfflineVideoDownloadStateDownloading:
            [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
            [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
            break;

        case BCOVOfflineVideoDownloadStateSuspended:
            [self.pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
            [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
            break;
            
        default:
            [self.pauseButton setTitle:@"--" forState:UIControlStateNormal];
            [self.cancelButton setTitle:@"--" forState:UIControlStateNormal];
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Handle swipe-to-delete for a downloaded video
    BCOVOfflineVideoToken offlineVideoToken = DownloadManager.sharedInstance.offlineVideoTokenArray[indexPath.row];
    
    // Delete from storage through the offline video mananger
    [DownloadManager.sharedInstance.offlineVideoManager deleteOfflineVideo:offlineVideoToken];
    
    // Report deletion so that the video page can update download status
    [InterfaceManager.sharedInstance.videosViewController didRemoveVideoFromTable:offlineVideoToken];
    
    // Remove from our local list of video tokens
    [DownloadManager.sharedInstance removeOfflineToken:offlineVideoToken];
    
    [self.downloadsTableView deleteRowsAtIndexPaths:@[indexPath]
                                   withRowAnimation:UITableViewRowAnimationFade];
    
    if (self.currentlyPlayingOfflineVideoToken != nil
        && [self.currentlyPlayingOfflineVideoToken isEqualToString:offlineVideoToken])
    {
        // Hide this video if it was playing
        [self doPlayHideButton:nil];
    }
    
    // Remove poster image:
    self.posterImageView.image = nil;
    
    // Update text in info panel
    [self updateInfoForSelectedDownload];
    
    [InterfaceManager.sharedInstance.videosViewController updateStatus];
    [self refresh];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%d Offline Videos", (int)DownloadManager.sharedInstance.offlineVideoTokenArray.count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSArray<BCOVOfflineVideoStatus *> *statusArray = [DownloadManager.sharedInstance.offlineVideoManager offlineVideoStatus];
    
    int inProgressCount = 0;
    for (BCOVOfflineVideoStatus *offlineVideoStatus in statusArray)
    {
        if (offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateDownloading)
        {
            inProgressCount ++;
        }
    }

    NSString *footerString;
    
    switch (inProgressCount)
    {
        case 0:
            footerString = [NSString stringWithFormat:@"All Videos Are Fully Downloaded"];
            break;
        case 1:
            footerString = [NSString stringWithFormat:@"1 Video Is Still Downloading"];
            break;
        default:
            footerString = [NSString stringWithFormat:@"%d Videos Are Still Downloading",
                            inProgressCount];
            break;
    }
    
    return footerString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTableViewCell *downloadCell = [tableView dequeueReusableCellWithIdentifier:@"VideoTableViewCell" forIndexPath:indexPath];
    
    BCOVOfflineVideoToken offlineVideoToken = DownloadManager.sharedInstance.offlineVideoTokenArray[indexPath.row];
    BCOVOfflineVideoStatus *offlineVideoStatus = [DownloadManager.sharedInstance.offlineVideoManager offlineVideoStatusForToken:offlineVideoToken];

    BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
    
    NSNumber *megabytesValue = self.downloadSizeDictionary[offlineVideoToken];
    double megabytes = 0.0;

    if (offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateCompleted)
    {
        // Compute size if it hasn't been done yet
        if (megabytesValue == nil)
        {
           NSString *videoFilePath = video.properties[kBCOVOfflineVideoFilePathPropertyKey];
           unsigned long long int videoSize = directorySize(videoFilePath);
           megabytes = (double)videoSize / (1000.0 * 1000.0);

           // Store the computed value
           self.downloadSizeDictionary[offlineVideoToken] = @(megabytes);
        }
        else
        {
           // use precomputed value
           megabytes = megabytesValue.doubleValue;
        }
    }
    
    [downloadCell setupWithOfflineVideo:video offlineStatus:offlineVideoStatus downloadSize:megabytes];
    
    return downloadCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return DownloadManager.sharedInstance.offlineVideoTokenArray.count;
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

@end

