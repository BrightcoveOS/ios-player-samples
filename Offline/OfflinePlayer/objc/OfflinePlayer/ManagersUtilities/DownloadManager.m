//
//  DownloadManager.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/30/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "DownloadManager.h"

#import "BCOVVIdeo+Convenience.h"
#import "SettingsAdapter.h"

@interface DownloadManager ()

@property (nonatomic, assign) BOOL downloadInProgress;
@property (nonatomic, strong, readwrite) NSArray<BCOVOfflineVideoToken> *offlineVideoTokenArray;

@end

@implementation DownloadManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static DownloadManager *downloadManager;
    dispatch_once(&onceToken, ^{
        downloadManager = [DownloadManager new];
    });
    return downloadManager;
}

#pragma mark - Private Methods

- (instancetype)init
{
    if (self = [super init])
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    NSDictionary *optionsDictionary =
    @{
      kBCOVOfflineVideoManagerAllowsCellularDownloadKey: @(NO),
      kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: @(NO),
      kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: @(NO)
      };
    [BCOVOfflineVideoManager initializeOfflineVideoManagerWithDelegate:self
                                                               options:optionsDictionary];
    self.offlineVideoManager = BCOVOfflineVideoManager.sharedManager;
    
    self.videoPreloadQueue = @[].mutableCopy;
    self.videoDownloadQueue = @[].mutableCopy;
}

- (void)notifyDelegateToRefreshUI
{
    if ([self.delegate respondsToSelector:@selector(shouldRefreshUI)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate shouldRefreshUI];
        });
    }
}

// Alert and return YES if the video is already downloaded or in a queue
- (BOOL)videoAlreadyProcessing:(BCOVVideo *)video
{
    BCOVOfflineVideoManager *ovm = BCOVOfflineVideoManager.sharedManager;

    // First check to see if the video is in a preload queue
    // videoPreloadQueue is an array of NSDictionary objects,
    // with a BCOVVideo under each "video" key.
    for (NSDictionary *videoDictionary in DownloadManager.sharedInstance.videoPreloadQueue)
    {
        BCOVVideo *testVideo = videoDictionary[@"video"];
        
        if ([video videoMatchesVideo:testVideo])
        {
            if ([self.delegate respondsToSelector:@selector(videoAlreadyPreloadQueued:)])
            {
                [self.delegate videoAlreadyPreloadQueued:video];
            }
            return YES;
        }
    }
    
    // First check to see if the video is in a download queue
    // videoDownloadQueue is an array of BCOVVideo objects
    for (NSDictionary *videoDownloadDictionary in DownloadManager.sharedInstance.videoDownloadQueue)
    {
        BCOVVideo *testVideo = videoDownloadDictionary[@"video"];
        if (testVideo == nil)
        {
            continue;
        }

        if ([video videoMatchesVideo:testVideo])
        {
            if ([self.delegate respondsToSelector:@selector(videoAlreadyDownloadQueued:)])
            {
                [self.delegate videoAlreadyDownloadQueued:video];
            }
            return YES;
        }
    }
    
    // Next check to see if the video has already been downloaded
    // or is in the process of downloading
    NSArray<BCOVOfflineVideoToken> *offlineVideoTokens = ovm.offlineVideoTokens;
    
    for (BCOVOfflineVideoToken offlineVideoToken in offlineVideoTokens)
    {
        BCOVVideo *testVideo = [ovm videoObjectFromOfflineVideoToken:offlineVideoToken];
        
        if ([video videoMatchesVideo:testVideo])
        {
            if ([self.delegate respondsToSelector:@selector(videoAlreadyDownloaded:)])
            {
                [self.delegate videoAlreadyDownloaded:video];
            }
            return YES;
        }
    }
    
    return NO;
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
        NSLog(@"Video \"%@\" does not use FairPlay; preloading not necessary", video.properties[kBCOVVideoPropertyKeyName]);
        [self.videoDownloadQueue addObject:videoDownloadDictionary];
        
        NSAssert(NSThread.isMainThread, @"Must update UI on main thread");
        [self notifyDelegateToRefreshUI];

        [self runPreloadVideoQueue];
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [BCOVOfflineVideoManager.sharedManager preloadFairPlayLicense:video
                                                           parameters:parameters
         
                                                           completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   
                                                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                   
                                                                   if (error == nil)
                                                                   {
                                                                       NSLog(@"Preloaded %@", offlineVideoToken);
                                                                       
                                                                       [strongSelf.videoDownloadQueue addObject:videoDownloadDictionary];
                                                                       
                                                                       [strongSelf notifyDelegateToRefreshUI];
                                                                   }
                                                                   else
                                                                   {
                                                                       if ([strongSelf.delegate respondsToSelector:@selector(encounteredErrorPreloading:forVideo:)])
                                                                       {
                                                                           BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
                                                                           [strongSelf.delegate encounteredErrorPreloading:error forVideo:video];
                                                                       }
                                                                   }
                                                                   
                                                                   [strongSelf runPreloadVideoQueue];
                                                                   
                                                               });
                                                               
                                                           }];
    }
}

- (void)downloadVideoFromQueue
{
    // If we're already downloading, this will be called automatically
    // when the download is done
    // Only needed for pre-iOS 11.4 only which can only handle
    // One download at a time
    if (@available(iOS 11.4, *))
    {}
    else if (self.downloadInProgress)
    {
        return;
    }
    
    NSDictionary *videoDownloadDictionary = self.videoDownloadQueue.firstObject;
    BCOVVideo *video = videoDownloadDictionary[@"video"];
    NSDictionary *parameters = videoDownloadDictionary[@"parameters"];

    if (video == nil)
    {
        // done!
        return;
    }
    
    [self.videoDownloadQueue removeObject:videoDownloadDictionary];
    
    self.downloadInProgress = YES;

    // Display all available bitrates
    [BCOVOfflineVideoManager.sharedManager variantBitratesForVideo:(BCOVVideo *)video
                                                        completion:^(NSArray<NSNumber *> *bitrates, NSError *error)
     {

         NSLog(@"Variant Bitrates for video: %@", video.properties[kBCOVVideoPropertyKeyName]);
         for (NSNumber *bitrateNumber in bitrates)
         {
             // Make sure the array contains the correct objects
             if (! [bitrateNumber isKindOfClass:NSNumber.class])
             {
                 NSLog(@"bitrateNumber contains the wrong class: %@", bitrateNumber.class.description);
             }
             
             NSLog(@"\t%d", bitrateNumber.intValue);
         }
     
     }];
    
    // Prior to iOS 13 it was possible to download secondary tracks separately from the video itself.
    // On iOS 13+ you must now download secondary tracks along with the video.
    // The existing method for downloading videos is: `requestVideoDownload:parameters:completion:`
    // You may still use this method on iOS 11 and 12.
    // If you want to support iOS 13 and do not want to have any branching logic
    // you can use the new method that is backwards compatible:
    // `requestVideoDownload:mediaSelections:parameters:completion:`
    
    __weak typeof(self) weakSelf = self;
    
    AVURLAsset *avURLAsset = [self.offlineVideoManager urlAssetForVideo:video error:nil];
    // If mediaSelections is `nil` the SDK will default to the AVURLAsset's `preferredMediaSelection`
    NSArray<AVMediaSelection *> *mediaSelections = nil;
    if (@available(iOS 11.0, *)) {
        mediaSelections = avURLAsset.allMediaSelections;
    }
    
    AVMediaSelectionGroup *legibleMediaSelectionGroup = [avURLAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionGroup *audibleMediaSelectionGroup = [avURLAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    
    int counter = 0;
    for (AVMediaSelection *s in mediaSelections)
    {
        AVMediaSelectionOption *legibleMediaSelectionOption = [s selectedMediaOptionInMediaSelectionGroup:legibleMediaSelectionGroup];
        AVMediaSelectionOption *audibleMediaSelectionOption = [s selectedMediaOptionInMediaSelectionGroup:audibleMediaSelectionGroup];

        NSLog(@"AVMediaSelection option %i | legible display name: %@", counter, legibleMediaSelectionOption.displayName ?: @"nil");
        NSLog(@"AVMediaSelection option %i | audible display name: %@", counter, audibleMediaSelectionOption.displayName ?: @"nil");
        
        counter++;
    }

    [self.offlineVideoManager requestVideoDownload:video
                                   mediaSelections:mediaSelections
                                        parameters:parameters
                                        completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {
                                            
                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                
                                                if (error == nil)
                                                {
                                                    // Success! Update our table with the new download status
                                                    if ([strongSelf.delegate respondsToSelector:@selector(videoDidBeginDownloading)])
                                                    {
                                                        [strongSelf.delegate videoDidBeginDownloading];
                                                    }
                                                }
                                                else
                                                {
                                                    strongSelf.downloadInProgress = NO;

                                                    // try again with another video
                                                    if (@available(iOS 11.4, *))
                                                    {}
                                                    else
                                                    {
                                                        [strongSelf downloadVideoFromQueue];
                                                    }

                                                    if ([strongSelf.delegate respondsToSelector:@selector(encounteredErrorDownloading:forVideo:)])
                                                    {
                                                        // Report any errors
                                                        BCOVVideo *video = [BCOVOfflineVideoManager.sharedManager videoObjectFromOfflineVideoToken:offlineVideoToken];
                                                        [strongSelf.delegate encounteredErrorDownloading:error forVideo:video];
                                                    }
                                                   
                                                }
                                                
                                            });
                                            
                                        }];
}

- (NSArray *)languagesArrayForAlternativeRenditions:(NSArray<NSDictionary *> *)alternativeRenditionAttributesDictionariesArray
{
    // We want to download all subtitle/audio tracks
    // The methods for dowloading them are different on iOS 10 and iOS 11+.
    
    if (alternativeRenditionAttributesDictionariesArray == nil)
    {
        return nil;
    }
    
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


#pragma mark - Public Methods

- (void)removeOfflineToken:(BCOVOfflineVideoToken)offlineVideoToken
{
    NSMutableArray *updatedOfflineVideoTokenArray = self.offlineVideoTokenArray.mutableCopy;
    [updatedOfflineVideoTokenArray removeObject:offlineVideoToken];
    self.offlineVideoTokenArray = updatedOfflineVideoTokenArray;
}

- (NSMutableDictionary *)generateLicenseParameters
{
    NSMutableDictionary *licenseParameters = @{}.mutableCopy;

    // Generate the license parameters based on the Settings tab
    BOOL isPurchaseLicense = SettingsAdapter.purchaseLicenseType;
    // License details are only needed for FairPlay-protected videos.
    // It's harmless to add it for non-FairPlay videos too.
    
    if (isPurchaseLicense)
    {
        NSLog(@"Requesting Purchase License");
        licenseParameters[kBCOVFairPlayLicensePurchaseKey] = @YES;
    }
    else
    {
        unsigned long long rentalDuration = SettingsAdapter.rentalDuration;
        
        NSLog(@"Requesting Rental License:\n"
              @"rentalDuration: %llu",
              rentalDuration);
        
        licenseParameters[kBCOVFairPlayLicenseRentalDurationKey] = @(rentalDuration);
    }

    return licenseParameters;
}

- (NSMutableDictionary *)generateDownloadParameters
{    
    // Get base license parameters
    NSMutableDictionary *downloadParameters = [self generateLicenseParameters];

    // Add bitrate parameter for the primary download
    long long int bitrate = SettingsAdapter.bitrate;
    
    NSLog(@"Requested bitrate: %lld", bitrate);
    
    downloadParameters[kBCOVOfflineVideoManagerRequestedBitrateKey] = @(bitrate);

    return downloadParameters;
}

- (void)downloadVideo:(BCOVVideo *)video
{
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

        NSDictionary *videoDownloadDictionary = @{
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
    
    __weak typeof(self) weakSelf = self;
    [BCOVOfflineVideoManager.sharedManager alternativeRenditionAttributesDictionariesForVideo:video
                                                                                   completion:^(NSArray<NSDictionary *> *alternativeRenditionAttributesDictionariesArray, NSError *error)
     {
         __strong typeof(weakSelf) strongSelf = weakSelf;
         // This can call back on a background thread
         dispatch_async(dispatch_get_main_queue(), ^{
             
             if (error != nil)
             {
                 if ([strongSelf.delegate respondsToSelector:@selector(encounteredGeneralError:)])
                 {
                     [strongSelf.delegate encounteredGeneralError:error];
                 }
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
                 NSDictionary *videoDownloadDictionary = @{
                   @"video": video,
                   @"parameters": downloadParameters
                };
                 
                 // On iOS 10.3 and later we can perform video preloading.
                 // Preloading the license makes for more reliable downloading
                 // when the app goes to the background.
                 [strongSelf.videoPreloadQueue addObject:videoDownloadDictionary];
                 
                 [strongSelf runPreloadVideoQueue];
             }
             else
             {
                 // On iOS 10.2 and earlier, just download immediately
                 [strongSelf.offlineVideoManager requestVideoDownload:video
                                                     parameters:downloadParameters
                                                     completion:^(BCOVOfflineVideoToken offlineVideoToken, NSError *error) {
                                                         
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             
                                                             if ([strongSelf.delegate respondsToSelector:@selector(downloadRequestDidComplete:)])
                                                             {
                                                                 [strongSelf.delegate downloadRequestDidComplete:error];
                                                             }
                                                             
                                                         });
                                                         
                                                     }];
             }
         });
         
     }];
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
                               completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        // Pass on to caller
        completionHandler(video, jsonResponse, error);

     }];
}

- (void)updateOfflineTokens
{
    // Refresh the list of downloaded videos from the offline video manager
    self.offlineVideoTokenArray = [self.offlineVideoManager offlineVideoTokens];
}

#pragma mark - BCOVOfflineVideoManagerDelegate Methods

- (void)offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
             downloadTask:(AVAssetDownloadTask *)downloadtask
            didProgressTo:(NSTimeInterval)percent
{
    // This delegate method reports progress for the primary video download
    NSLog(@"Offline download didProgressTo: %0.2f%% for token: %@", (float)percent, offlineVideoToken);
    
    dispatch_async(dispatch_get_main_queue(), ^{

        if ([self.delegate respondsToSelector:@selector(downloadDidProgressTo:)])
        {
            [self.delegate downloadDidProgressTo:percent];
        }

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
    
    self.downloadInProgress = NO;
    
    // Get the next video
    if (@available(iOS 11.4, *))
    {}
    else
    {
        [self downloadVideoFromQueue];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(videoDidFinishDownloadingWithError:)])
        {
            [self.delegate videoDidFinishDownloadingWithError:error];
        }
        
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
        
        if ([self.delegate respondsToSelector:@selector(downloadDidProgressTo:)])
        {
            [self.delegate downloadDidProgressTo:progressPercent];
        }
        
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
        
        if ([self.delegate respondsToSelector:@selector(videoDidFinishDownloadingWithError:)])
        {
            [self.delegate videoDidFinishDownloadingWithError:error];
        }
        
    });
}

- (void)didDownloadStaticImagesWithOfflineVideoToken:(BCOVOfflineVideoToken)offlineVideoToken
{
    // Called when the thumbnail and poster frame downloads
    // for the specified video token are complete
}

@end
