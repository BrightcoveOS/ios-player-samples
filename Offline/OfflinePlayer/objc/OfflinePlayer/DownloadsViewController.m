//
//  DownloadsViewController.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVOfflineVideoStatus+OfflinePlayer.h"
#import "BCOVVideo+OfflinePlayer.h"
#import "DownloadManager.h"
#import "Notifications.h"
#import "UIAlertController+OfflinePlayer.h"
#import "UIDevice+OfflinePlayer.h"
#import "UITabBarController+OfflinePlayer.h"
#import "VideoManager.h"
#import "VideoTableViewCell.h"

#import "DownloadsViewController.h"


// The Downloads View Controller displays a list of HLS videos that have been
// downloaded, including videos that are "preloaded", meaning their FairPlay
// licenses have been acquired, and the video content is yet to be downloaded.
//
// You can tap on a video to select it, and thus display information about it.
//
// After selecting it, tap "play" to play the video.
//
// Slide to delete a video.
//
// Tap "More…" to log information about the current video, renew the FairPlay
// license, or delete the video.


@interface DownloadsViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIImageView *posterImageView;
@property (nonatomic, weak) IBOutlet UILabel *infoLabel;
@property (nonatomic, weak) IBOutlet UILabel *noVideoSelectedLabel;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *moreButton;
@property (nonatomic, weak) IBOutlet UILabel *taskLabel;
@property (nonatomic, weak) IBOutlet UIButton *pauseButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *headerTableView;
@property (nonatomic, weak) IBOutlet UIView *footerTableView;

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *downloadVideosLabel;
@property (nonatomic, strong) UILabel *freeSpaceLabel;

@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) NSString *selectedOfflineVideoToken;
@property (nonatomic, strong) NSString *currentlyPlayingOfflineVideoToken;

@property (nonatomic, strong) NSTimer *freeSpaceTimer;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation DownloadsViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.videoContainerView.hidden = YES;
    self.posterImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.posterImageView.clipsToBounds = YES;
    self.infoLabel.hidden = YES;
    self.infoLabel.numberOfLines = 10;

    self.playButton.hidden = YES;
    self.moreButton.hidden = YES;
    self.taskLabel.hidden = YES;
    self.pauseButton.hidden = YES;
    self.cancelButton.hidden = YES;

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.headerLabel = ({
        CGSize size = self.headerTableView.frame.size;
        CGRect frame = CGRectMake(20, 0, size.width - 40, size.height);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentJustified;
        label.font = [UIFont boldSystemFontOfSize:16];
        label.textColor = UIColor.systemGrayColor;
        label.backgroundColor = UIColor.clearColor;
        label;
    });

    self.headerTableView.layer.borderColor = [UIColor colorWithWhite:0.9f
                                                               alpha:1.0f].CGColor;
    self.headerTableView.layer.borderWidth = 0.3f;
    [self.headerTableView addSubview:self.headerLabel];

    self.downloadVideosLabel = ({
        CGSize size = self.footerTableView.frame.size;
        CGRect frame = CGRectMake(20, 0, size.width - 40, 28);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentJustified;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.textColor = UIColor.systemGrayColor;
        label.backgroundColor = UIColor.clearColor;
        label;
    });

    self.freeSpaceLabel = ({
        CGSize size = self.footerTableView.frame.size;
        CGRect frame = CGRectMake(0, 28, size.width, 28);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.backgroundColor = [UIColor colorWithWhite:0.9f
                                                  alpha:1.0f];
        label;
    });

    self.footerTableView.layer.borderColor = [UIColor colorWithWhite:0.9f
                                                               alpha:1.0f].CGColor;
    self.footerTableView.layer.borderWidth = 0.3f;
    [self.footerTableView addSubview:self.downloadVideosLabel];
    [self.footerTableView addSubview:self.freeSpaceLabel];

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

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

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

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateStatus:)
                                               name:UpdateStatus
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.freeSpaceTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                                           target:self
                                                         selector:@selector(updateFreeSpaceLabel)
                                                         userInfo:nil
                                                          repeats:YES];

    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                      object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.freeSpaceTimer invalidate];
    self.freeSpaceTimer = nil;
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;

    self.tabBarController.tabBar.hidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setSelectedOfflineVideoToken:(NSString *)selectedOfflineVideoToken
{
    _selectedOfflineVideoToken = selectedOfflineVideoToken;

    [self resetVideoContainer];

    [self updateInfoForSelectedDownload];

    [self updateButtonTitles];
}

- (void)updateStatus:(NSNotification *)notification
{
    NSAssert(NSThread.isMainThread, @"Must update UI on main thread");

    dispatch_async(dispatch_get_main_queue(), ^{

        NSArray *offlineVideoStatusArray = [BCOVOfflineVideoManager.sharedManager offlineVideoStatus];
        NSArray *offlineVideoTokens = BCOVOfflineVideoManager.sharedManager.offlineVideoTokens;

        BCOVVideo *offlineVideo = notification.object;

        if (self.isVisible && offlineVideo.offlineVideoToken)
        {
            NSUInteger index = [offlineVideoTokens indexOfObject:offlineVideo.offlineVideoToken];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                        inSection:0];

            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
                                  
            [self updateInfoForSelectedDownload];
            
            [self updateButtonTitles];
        }
        else
        {
            [self.tableView reloadData];
        }

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.downloadState == %i",
                                  BCOVOfflineVideoDownloadStateDownloading];
        NSUInteger inProgressCount = [offlineVideoStatusArray filteredArrayUsingPredicate:predicate].count;

        switch (inProgressCount)
        {
            case 0:
                self.downloadVideosLabel.text = @"No Videos Downloading";
                break;

            case 1:
                self.downloadVideosLabel.text = @"1 Video is still Downloading";
                break;

            default:
                self.downloadVideosLabel.text =
                [NSString stringWithFormat:@"%lu Videos are still Downloading", inProgressCount];
        }

        self.headerLabel.text = [NSString stringWithFormat:@"%lu Offline %@",
                                 offlineVideoTokens.count,
                                 offlineVideoTokens.count != 1 ? @"Videos" : @"Video"];

        [self updateFreeSpaceLabel];
    });
}

- (void)updateFreeSpaceLabel
{
    NSString *freeDiskSpace = UIDevice.currentDevice.freeDiskSpace;

    if (freeDiskSpace.longLongValue < 50)
    {
        self.freeSpaceLabel.textColor = UIColor.systemOrangeColor;
    }
    else if (freeDiskSpace.longLongValue < 10)
    {
        self.freeSpaceLabel.textColor = UIColor.systemRedColor;
    }
    else
    {
        self.freeSpaceLabel.textColor = UIColor.systemGrayColor;
    }

    self.freeSpaceLabel.text = [NSString stringWithFormat:@"Free: %@ GB of %@ GB",
                                freeDiskSpace,
                                UIDevice.currentDevice.totalDiskSpace];
}

- (void)resetVideoContainer
{
    self.videoContainerView.hidden = YES;

    [self.playbackController pause];
    [self.playbackController setVideos:nil];

    self.currentlyPlayingOfflineVideoToken = nil;
}

- (void)updateInfoForSelectedDownload
{
    self.noVideoSelectedLabel.hidden = self.selectedOfflineVideoToken != nil;
    self.posterImageView.hidden = self.selectedOfflineVideoToken == nil;
    self.infoLabel.hidden = self.selectedOfflineVideoToken == nil;

    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];

    NSString *posterPath = offlineVideo.properties[kBCOVOfflineVideoPosterFilePathPropertyKey];
    UIImage *poster = [UIImage imageWithContentsOfFile:posterPath] ?: [UIImage imageNamed:@"AppIcon"];
    self.posterImageView.backgroundColor = posterPath != nil ? UIColor.clearColor : UIColor.blackColor;
    self.posterImageView.image = poster;

    BCOVOfflineVideoStatus *status = [BCOVOfflineVideoManager.sharedManager
                                      offlineVideoStatusForToken:self.selectedOfflineVideoToken];

    self.infoLabel.text = [NSString stringWithFormat:@"%@\nLicense: %@\nStatus: %@",
                           offlineVideo.localizedName ?: @"unknown",
                           offlineVideo.license,
                           status.infoForDonwloadState];

    [self.infoLabel sizeToFit];
}

- (void)updateButtonTitles
{
    BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager
                                                  offlineVideoStatusForToken:self.selectedOfflineVideoToken];

    if (offlineVideoStatus)
    {
        BOOL showTaskButtons = ![@[@(BCOVOfflineVideoDownloadStateDownloading),
                                   @(BCOVOfflineVideoDownloadStateSuspended)] containsObject:@(offlineVideoStatus.downloadState)];

        self.playButton.hidden = NO;
        self.moreButton.hidden = NO;
        self.taskLabel.hidden = showTaskButtons;
        self.pauseButton.hidden = showTaskButtons;
        self.cancelButton.hidden = showTaskButtons;

        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];

        switch (offlineVideoStatus.downloadState)
        {
            case BCOVOfflineVideoDownloadStateDownloading:
                [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
                break;

            case BCOVOfflineVideoDownloadStateSuspended:
                [self.pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
                break;

            default:
                break;
        }
    }
    else
    {
        self.playButton.hidden = YES;
        self.moreButton.hidden = YES;
        self.taskLabel.hidden = YES;
        self.pauseButton.hidden = YES;
        self.cancelButton.hidden = YES;
    }
}

- (void)deleteVideoForOfflineVideoToken:(NSString *)offlineVideoToken
{
    [BCOVOfflineVideoManager.sharedManager deleteOfflineVideo:offlineVideoToken];

    if ([offlineVideoToken isEqualToString:self.selectedOfflineVideoToken] ||
        [offlineVideoToken isEqualToString:self.currentlyPlayingOfflineVideoToken] ||
        BCOVOfflineVideoManager.sharedManager.offlineVideoTokens.count == 0)
    {
        self.selectedOfflineVideoToken = nil;
    }

    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                      object:nil];
}

- (void)renewLicenseForOfflineVideoToken:(NSString *)offlineVideoToken
{
    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:offlineVideoToken];

    [VideoManager.shared retrieveVideo:offlineVideo
                            completion:^(BCOVVideo *video,
                                         NSDictionary *jsonResponse,
                                         NSError *error) {
        if (error)
        {
            NSLog(@"Could not retrieve new video during FairPlay license renewal. Error: %@", error.localizedDescription);

            dispatch_async(dispatch_get_main_queue(), ^{
                // Show the new license
                [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                                  object:nil];
            });
        }

        if (video)
        {
            NSDictionary *licenseParameters = DownloadManager.licenseParameters;
            [BCOVOfflineVideoManager.sharedManager renewFairPlayLicense:offlineVideoToken
                                                                  video:video
                                                             parameters:licenseParameters
                                                             completion:^(BCOVOfflineVideoToken
                                                                          offlineVideoToken,
                                                                          NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> _Nonnull mutableVideo) {
                        NSMutableDictionary *mutableProperties = mutableVideo.properties.mutableCopy;
                        if (offlineVideoToken)
                        {
                            mutableProperties[kBCOVOfflineVideoTokenPropertyKey] = offlineVideoToken;
                            mutableVideo.properties = mutableProperties;
                        }
                    }];

                    // Show the new license
                    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                                      object:updatedVideo];
                });
            }];
        }
    }];
}

- (void)confirmDeletionForVideo:(BCOVVideo *)video
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Delete Offline Video"
                                        message:[NSString stringWithFormat:@"Are you sure you want to delete the offline video \"%@\"",
                                                 video.localizedName ?: @"unknown"]
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Delete Offline Video"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self deleteVideoForOfflineVideoToken:video.offlineVideoToken];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)cancelVideoDownload
{
    BCOVOfflineVideoStatus *status = [BCOVOfflineVideoManager.sharedManager
                                      offlineVideoStatusForToken:self.selectedOfflineVideoToken];
    switch (status.downloadState)
    {
        case BCOVOfflineVideoDownloadStateRequested:
        case BCOVOfflineVideoDownloadStateDownloading:
        case BCOVOfflineVideoDownloadStateSuspended:
            [BCOVOfflineVideoManager.sharedManager
             cancelVideoDownload:self.selectedOfflineVideoToken];
            break;

        default:
            break;
    }
}

- (void)logStatus
{
    // Log a variety of information to the debug console
    // about the currently selected offline video token.
    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];
    if (!offlineVideo)
    {
        NSLog(@"Could not find video for token %@", self.selectedOfflineVideoToken);
        return;
    }

    NSLog(@"Video Properties:\n%@", offlineVideo.properties);
}

- (IBAction)doPlayHideButton:(UIButton *)sender
{
    if (!self.selectedOfflineVideoToken)
    {
        return;
    }

    if (self.selectedOfflineVideoToken != self.currentlyPlayingOfflineVideoToken)
    {
        // iOS 13 returns an incorrect value for `playableOffline`
        // if the offline video is already loaded into an
        // AVPlayer instance. Clearing out the current AVPlayer
        // instance solves the issue.
        [self.playbackController setVideos:nil];

        BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager
                                                      offlineVideoStatusForToken:self.selectedOfflineVideoToken];
        if (offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateCancelled)
        {
            [UIAlertController showWithTitle:@""
                                     message:@"This video is not currently playable. The download was cancelled."];
            return;
        }

        if (!offlineVideoStatus.offlineVideo.playableOffline)
        {
            [UIAlertController showWithTitle:@""
                                     message:@"This video is not currently playable. The download may still be in progress."];
            return;
        }

        [self.playbackController setVideos:@[ offlineVideoStatus.offlineVideo ]];
        self.currentlyPlayingOfflineVideoToken = self.selectedOfflineVideoToken;
    }

    [self.playButton setTitle:([sender.titleLabel.text isEqualToString:@"Play"] ? @"Hide" : @"Play")
                     forState:UIControlStateNormal];
    self.posterImageView.hidden = !self.posterImageView.isHidden;
    self.infoLabel.hidden = !self.infoLabel.isHidden;
    self.videoContainerView.hidden = !self.videoContainerView.isHidden;
}

- (IBAction)doMoreButton:(UIButton *)button
{
    if (!self.selectedOfflineVideoToken)
    {
        [UIAlertController showWithTitle:@"More Options"
                                 message:@"No video was selected"];

        return;
    }

    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:self.selectedOfflineVideoToken];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"More Options"
                                                                   message:[NSString stringWithFormat:@"Additional options for offline video \"%@\"",
                                                                            offlineVideo.localizedName ?: @"unknown"]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Log Status"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self logStatus];
    }]];

    if (offlineVideo.usesFairPlay)
    {
        [alert addAction:[UIAlertAction actionWithTitle:@"Renew License"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self renewLicenseForOfflineVideoToken:self.selectedOfflineVideoToken];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Delete Offline Video"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self confirmDeletionForVideo:offlineVideo];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)doPauseResumeButton:(UIButton *)sender
{
    // Pause or resume based on the current state of the download
    BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager
                                                  offlineVideoStatusForToken:self.selectedOfflineVideoToken];
    if (offlineVideoStatus)
    {
        switch (offlineVideoStatus.downloadState)
        {
            case BCOVOfflineVideoDownloadStateDownloading:
                [BCOVOfflineVideoManager.sharedManager
                 pauseVideoDownload:self.selectedOfflineVideoToken];
                break;

            case BCOVOfflineVideoDownloadStateSuspended:
                [BCOVOfflineVideoManager.sharedManager
                 resumeVideoDownload:self.selectedOfflineVideoToken];
                break;;

            default:
                break;
        }

        // Disable pause button for a moment to prevent button spamming
        self.pauseButton.enabled = NO;
        [NSTimer scheduledTimerWithTimeInterval:1.0f
                                        repeats:NO
                                          block:^(NSTimer * _Nonnull timer) {
            self.pauseButton.enabled = YES;
        }];

        [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                          object:offlineVideoStatus.offlineVideo];
    }
}

- (IBAction)doCancelButton:(UIButton *)sender
{
    [self cancelVideoDownload];
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
        NSError *error = lifecycleEvent.properties[kBCOVPlaybackSessionEventKeyError];
        NSLog(@"Error: `%@`", error.localizedDescription);

        if (kBCOVOfflineVideoManagerErrorCodeExpiredLicense == error.code)
        {
            NSLog(@"License has expired for the video \"%@\"",
                  session.video.localizedName ?: @"unknown");

            [UIAlertController showWithTitle:@"License Expired"
                                     message:[NSString stringWithFormat:@"The FairPlay license for the video \"%@\" has expired.",
                                              session.video.localizedName ?: @"unknown"]];
        }
    }
}


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return BCOVOfflineVideoManager.sharedManager.offlineVideoTokens.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:@"VideoTableViewCell"
                                                                    forIndexPath:indexPath];

    if (videoCell)
    {
        NSArray *offlineVideoTokens = BCOVOfflineVideoManager.sharedManager.offlineVideoTokens;
        NSString *offlineVideoToken = offlineVideoTokens[indexPath.row];
        BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                                   videoObjectFromOfflineVideoToken:offlineVideoToken];

        [videoCell setupWithVideo:offlineVideo
                      andDelegate:nil];
    }

    return videoCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *offlineVideoStatusArray = [BCOVOfflineVideoManager.sharedManager offlineVideoStatus];

    BCOVOfflineVideoStatus *offlineVideoStatus = offlineVideoStatusArray[indexPath.row];

    return offlineVideoStatus.downloadState != BCOVOfflineVideoDownloadStateDownloading;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *offlineVideoTokens = BCOVOfflineVideoManager.sharedManager.offlineVideoTokens;
    NSString *offlineVideoToken = offlineVideoTokens[indexPath.row];

    [self deleteVideoForOfflineVideoToken:offlineVideoToken];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSArray *offlineVideoTokens = BCOVOfflineVideoManager.sharedManager.offlineVideoTokens;
    self.selectedOfflineVideoToken = offlineVideoTokens[indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

@end
