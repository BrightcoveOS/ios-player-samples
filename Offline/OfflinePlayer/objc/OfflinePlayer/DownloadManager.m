//
//  DownloadManager.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "BCOVVideo+OfflinePlayer.h"
#import "Notifications.h"
#import "SettingsViewController.h"
#import "UIAlertController+OfflinePlayer.h"
#import "UITabBarController+OfflinePlayer.h"

#import "DownloadManager.h"


@interface DownloadManager ()

// The download queue.
// Videos go into the preload queue first.
// When all preloads are done, videos move to the download queue.
@property (nonatomic, strong) NSMutableArray *videoPreloadQueue;
@property (nonatomic, strong) NSMutableArray *videoDownloadQueue;

@end


@implementation DownloadManager

+ (instancetype)shared
{
    static DownloadManager *downloadManager;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        downloadManager = [DownloadManager new];
    });

    return downloadManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.videoDownloadQueue = @[].mutableCopy;
        self.videoPreloadQueue = @[].mutableCopy;
    }

    return self;
}

+ (NSDictionary *)licenseParameters
{
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    UITabBarController *rootViewController = (UITabBarController *)window.rootViewController;
    SettingsViewController *settingsViewController = rootViewController.settingsViewController;

    if (settingsViewController)
    {
        NSMutableDictionary *licenseParamaters = [NSMutableDictionary new];

        // Generate the license parameters based on the Settings tab
        BOOL isPurchaseLicense = settingsViewController.purchaseLicenseType;

        // License details are only needed for FairPlay-protected videos.
        // It's harmless to add it for non-FairPlay videos too.
        if (isPurchaseLicense)
        {
            NSLog(@"Requesting Purchase License");
            licenseParamaters[kBCOVFairPlayLicensePurchaseKey] = @(YES);
        }
        else
        {
            UInt64 rentalDuration = settingsViewController.rentalDuration;
            UInt64 playDuration = settingsViewController.playDuration;

            licenseParamaters[kBCOVFairPlayLicenseRentalDurationKey] = @(rentalDuration);
            licenseParamaters[kBCOVFairPlayLicensePlayDurationKey] = @(playDuration);

            NSLog(@"Requesting Rental License\nrentalDuration: %llu\nplayDuration: %llu",
                  rentalDuration, playDuration);
        }

        return licenseParamaters.copy;

    }

    return @{};
}

+ (NSDictionary *)downloadParameters
{
    // Get base license parameters
    NSDictionary *licenseParameters = DownloadManager.licenseParameters;
    NSMutableDictionary *downloadParameters = [[NSMutableDictionary alloc] initWithDictionary:licenseParameters];

    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    UITabBarController *rootViewController = (UITabBarController *)window.rootViewController;
    SettingsViewController *settingsViewController = rootViewController.settingsViewController;

    if (settingsViewController)
    {
        // Add bitrate parameter for the primary download
        UInt64 bitrate = settingsViewController.bitrate;

        NSLog(@"Requested bitrate: %llu", bitrate);
        downloadParameters[kBCOVOfflineVideoManagerRequestedBitrateKey] = @(bitrate);
    }

    return downloadParameters.copy;
}

- (void)doDownloadForVideo:(BCOVVideo *)video
{
    if ([self videoAlreadyProcessing:video])
    {
        return;
    }

    NSDictionary *downloadParamaters = DownloadManager.downloadParameters;

    NSDictionary *videoDownload = @{
        @"video": video,
        @"parameters": downloadParamaters
    };

    [self.videoPreloadQueue addObject:videoDownload];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self runPreloadVideoQueue];
    });
}

- (BOOL)videoAlreadyProcessing:(BCOVVideo *)video
{
    // First check to see if the video is in a preload queue
    // videoPreloadQueue is an array of NSDictionary objects,
    // with a BCOVVideo under each "video" key.
    for (NSDictionary *videoDownload in self.videoPreloadQueue)
    {
        BCOVVideo *videoDict = videoDownload[@"video"];
        if ([videoDict matchesWithVideo:video])
        {
            [UIAlertController showWithTitle:@"Video Already in Preload Queue"
                                     message:[NSString stringWithFormat:@"The video %@ is already queued to be preloaded",
                                              video.localizedName ?: @"unknown"]];
            return YES;
        }
    }

    // First check to see if the video is in a download queue
    // videoDownloadQueue is an array of NSDictionary objects,
    // with a BCOVVideo under each "video" key.
    for (NSDictionary *videoDownload in self.videoDownloadQueue)
    {
        BCOVVideo *videoDict = videoDownload[@"video"];
        if ([videoDict matchesWithVideo:video])
        {
            [UIAlertController showWithTitle:@"Video Already in Download Queue"
                                     message:[NSString stringWithFormat:@"The video %@ is already queued to be downloaded",
                                              video.localizedName ?: @"unknown"]];
            return YES;
        }
    }

    // Next check to see if the video has already been downloaded
    // or is in the process of downloading
    NSArray *offlineVideoTokens = BCOVOfflineVideoManager.sharedManager.offlineVideoTokens;
    for (NSString *offlineVideoToken in offlineVideoTokens)
    {
        BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                                   videoObjectFromOfflineVideoToken:offlineVideoToken];
        if (![offlineVideo matchesWithVideo:video])
        {
            continue;
        }

        BCOVOfflineVideoStatus *offlineVideoStatus = [BCOVOfflineVideoManager.sharedManager
                                                      offlineVideoStatusForToken:offlineVideoToken];
        if (offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateError ||
            offlineVideoStatus.downloadState == BCOVOfflineVideoDownloadStateCancelled)
        {
            [UIAlertController showWithTitle:@"Video Failed to Download"
                                     message:[NSString stringWithFormat:@"The video %@ previously failed to download or was cancelled, would you like to try again?",
                                              video.localizedName ?: @"unknown"]
                                 actionTitle:@"Retry"
                                 cancelTitle:@"Cancel"
                                  completion:^{

                NSLog(@"Deleting previous download for video and attempting again.");
                [BCOVOfflineVideoManager.sharedManager deleteOfflineVideo:offlineVideoToken];
                [DownloadManager.shared doDownloadForVideo:video];

            }];

            return YES;
        }

        [UIAlertController showWithTitle:@"Video Already Downloaded"
                                 message:[NSString stringWithFormat:@"The video %@ is already downloaded (or downloading)",
                                          video.localizedName ?: @"unknown"]];
        return YES;
    }

    return NO;
}

- (void)runPreloadVideoQueue
{
    NSDictionary *videoDownload = self.videoPreloadQueue.firstObject;
    if (!videoDownload)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadVideoFromQueue];
        });

        return;
    }

    [self.videoPreloadQueue removeObject:videoDownload];

    BCOVVideo *video = videoDownload[@"video"];
    NSDictionary *parameters = videoDownload[@"parameters"];

    // Preloading only applies to FairPlay-protected videos.
    // If there's no FairPlay involved, the video is moved on
    // to the video download queue.
    if (!video.usesFairPlay)
    {
        NSLog(@"Video \"%@\" does not use FairPlay; preloading not necessary",
              video.localizedName ?: @"unknown");

        [self.videoDownloadQueue addObject:videoDownload];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self runPreloadVideoQueue];

            [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                              object:video];
        });
    }
    else
    {
        __weak typeof(self) weakSelf = self;

        [BCOVOfflineVideoManager.sharedManager preloadFairPlayLicense:video
                                                           parameters:parameters
                                                           completion:^(BCOVOfflineVideoToken offlineVideoToken,
                                                                        NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                    // Report any errors
                    [UIAlertController showWithTitle:[NSString stringWithFormat:@"Video Preload Error\n(%@)",
                                                      video.localizedName ?: @"unknown"]
                                             message:error.localizedDescription];
                }
                else
                {
                    NSLog(@"Preloaded %@", offlineVideoToken);
                    [strongSelf.videoDownloadQueue addObject:videoDownload];
                }

                [strongSelf runPreloadVideoQueue];

                [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                                  object:nil];
            });
        }];
    }
}

- (void)downloadVideoFromQueue
{
    NSDictionary *videoDownload = self.videoDownloadQueue.firstObject;
    if (!videoDownload)
    {
        return;
    }

    [self.videoDownloadQueue removeObject:videoDownload];

    BCOVVideo *video = videoDownload[@"video"];
    NSDictionary *parameters = videoDownload[@"parameters"];

    // Display all available bitrates
    [BCOVOfflineVideoManager.sharedManager variantBitratesForVideo:video
                                                        completion:^(NSArray<NSNumber *> *bitrates,
                                                                     NSError *error) {

        NSLog(@"Variant Bitrates for video: %@", video.localizedName ?: @"unknown");
        for (NSNumber *bitrate in bitrates)
        {
            NSLog(@"%i", bitrate.intValue);
        }
    }];

    AVURLAsset *urlAsset = [BCOVOfflineVideoManager.sharedManager urlAssetForVideo:video
                                                                             error:nil];

    // HLSe (AES-128) streams are not supported for offline playback
    if ([urlAsset.URL.absoluteString containsString:@"aes128"])
    {
        [UIAlertController showWithTitle:@"Content Not Supported"
                                 message:@"Offline playback is not supported for HLSe content."];
        return;
    }

    // If mediaSelections is `nil` the SDK will default
    // to the AVURLAsset's `preferredMediaSelection`
    NSArray<AVMediaSelection *> *mediaSelections = urlAsset.allMediaSelections;

    AVMediaSelectionGroup *legibleMediaSelectionGroup = [urlAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionGroup *audibleMediaSelectionGroup = [urlAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];

    [urlAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];

    int counter = 0;
    for (AVMediaSelection *selection in mediaSelections)
    {
        AVMediaSelectionOption *legibleMediaSelectionOption = [selection selectedMediaOptionInMediaSelectionGroup:legibleMediaSelectionGroup];
        AVMediaSelectionOption *audibleMediaSelectionOption = [selection selectedMediaOptionInMediaSelectionGroup:audibleMediaSelectionGroup];

        NSLog(@"AVMediaSelection option %i | legible display name: %@",
              counter, legibleMediaSelectionOption.displayName ?: @"nil");
        NSLog(@"AVMediaSelection option %i | audible display name: %@",
              counter, audibleMediaSelectionOption.displayName ?: @"nil");

        counter++;
    }

    [BCOVOfflineVideoManager.sharedManager requestVideoDownload:video
                                                mediaSelections:mediaSelections
                                                     parameters:parameters
                                                     completion:^(BCOVOfflineVideoToken offlineVideoToken,
                                                                  NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                // Report any errors
                [UIAlertController showWithTitle:[NSString stringWithFormat:@"Video Download Error\n (%@)",
                                                  video.localizedName ?: @"unknown"]
                                         message:error.localizedDescription];
            }

            [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                              object:nil];
        });
    }];
}

- (NSString *)mediaSelectionDescription:(AVMediaSelection *)mediaSelection
                               urlAsset:(AVURLAsset *)urlAsset
{
    // Return a string description of the specified Media Selection.
    AVMediaSelectionGroup *legibleMediaSelectionGroup = [urlAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionGroup *audibleMediaSelectionGroup = [urlAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    AVMediaSelectionOption *legibleMediaSelectionOption = [mediaSelection selectedMediaOptionInMediaSelectionGroup:legibleMediaSelectionGroup];
    AVMediaSelectionOption *audibleMediaSelectionOption = [mediaSelection selectedMediaOptionInMediaSelectionGroup:audibleMediaSelectionGroup];

    NSString *description = [NSString stringWithFormat:@"MediaSelection(obj:%p, legible:%@, audible:%@)",
                             mediaSelection,
                             legibleMediaSelectionOption.displayName ?: @"-",
                             audibleMediaSelectionOption.displayName ?: @"-"];
    return description;
}

- (NSString *)mediaSelectionDescription:(AVMediaSelection *)mediaSelection
                      offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
{
    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:offlineVideoToken];

    // Get the path to the locally stored video and make an AVURLAsset out of it
    NSString *offlineVideoPath = offlineVideo.properties[kBCOVOfflineVideoFilePathPropertyKey];
    if (!offlineVideoPath)
    {
        return @"MediaSelection(n/a)";
    }

    NSURL *offlineVideoPathURL = [NSURL fileURLWithPath:offlineVideoPath];
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:offlineVideoPathURL];
    NSString *description = [self mediaSelectionDescription:mediaSelection
                                                   urlAsset:urlAsset];
    return description;
}


#pragma mark - BCOVOfflineVideoManagerDelegate

- (void)didCreateSharedBackgroundSesssionConfiguration:(NSURLSessionConfiguration *)backgroundSessionConfiguration
{
    // Helps prevent downloads from appearing to sometimes stall
    backgroundSessionConfiguration.discretionary = NO;
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
    aggregateDownloadTask:(AVAggregateAssetDownloadTask *)aggregateDownloadTask
            didProgressTo:(NSTimeInterval)progressPercent
        forMediaSelection:(AVMediaSelection *)mediaSelection
{
    // The specific requested media selected option related to this
    // offline video token has progressed to the specified percent
    NSLog(@"aggregateDownloadTask:didProgressTo: %0.2f for token: %@",
          progressPercent, offlineVideoToken);

    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:offlineVideoToken];

    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                      object:offlineVideo];
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
didFinishMediaSelectionDownload:(AVMediaSelection *)mediaSelection
{
    // The specific requested media selected option related to this
    // offline video token has completed downloading
    BCOVOfflineVideoStatus *offlineStatus = [BCOVOfflineVideoManager.sharedManager
                                             offlineVideoStatusForToken:offlineVideoToken];

    AVURLAsset *urlAsset = offlineStatus.aggregateDownloadTask.URLAsset;
    NSString *mediaSelectionDescription = [self mediaSelectionDescription:mediaSelection
                                                                 urlAsset:urlAsset];

    NSLog(@"didFinishMediaSelectionDownload: %@ for token: %@",
          mediaSelectionDescription, offlineVideoToken);
}

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
didFinishDownloadWithError:(NSError *)error
{
    // The video has completed downloading
    if (error)
    {
        NSLog(@"Download finished with error: %@", error.localizedDescription);
    }

    BCOVVideo *offlineVideo = [BCOVOfflineVideoManager.sharedManager
                               videoObjectFromOfflineVideoToken:offlineVideoToken];

    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                      object:offlineVideo];
}

- (void)offlineVideoStorageDidChange
{
    [NSNotificationCenter.defaultCenter postNotificationName:UpdateStatus
                                                      object:nil];
}

@end
