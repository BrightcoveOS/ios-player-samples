//
//  DownloadManager.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/30/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

// Dynamic Delivery account credentials
// Your account can contain FairPlay-protected HLS videos, or unprotected HLS videos
static NSString * _Nonnull const kDynamicDeliveryAccountID = @"5434391461001";
static NSString * _Nonnull const kDynamicDeliveryPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * _Nonnull const kDynamicDeliveryPlaylistRefID = @"brightcove-native-sdk-plist";

@import BrightcovePlayerSDK;

NS_ASSUME_NONNULL_BEGIN

@protocol DownloadManagerDelegate <NSObject>

- (void)shouldRefreshUI;

- (void)encounteredGeneralError:(NSError *)error;
- (void)downloadRequestDidComplete:(NSError * _Nullable)error;
- (void)encounteredErrorPreloading:(NSError *)error forVideo:(BCOVVideo *)video;
- (void)encounteredErrorDownloading:(NSError *)error forVideo:(BCOVVideo *)video;
- (void)videoDidBeginDownloading;
- (void)videoDidFinishDownloadingWithError:(NSError * _Nullable)error;
- (void)downloadDidProgressTo:(NSTimeInterval)percent;
- (void)videoAlreadyPreloadQueued:(BCOVVideo *)video;
- (void)videoAlreadyDownloadQueued:(BCOVVideo *)video;
- (void)videoAlreadyDownloaded:(BCOVVideo *)video;

@end

@interface DownloadManager : NSObject<BCOVOfflineVideoManagerDelegate>

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<DownloadManagerDelegate> delegate;

@property (nonatomic, strong) BCOVOfflineVideoManager *offlineVideoManager;

// List of all the currently downloaded videos (as offline video tokens)
@property (nonatomic, strong, readonly) NSArray<BCOVOfflineVideoToken> *offlineVideoTokenArray;

// The download queue.
// Videos go into the preload queue first.
// When all preloads are done, videos move to the download queue.
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *videoPreloadQueue;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *videoDownloadQueue;

- (void)removeOfflineToken:(BCOVOfflineVideoToken)offlineVideoToken;

// Give other controllers a way to retrieve videos.
// Used for FairPlay license renewal.
- (void)retrieveVideoWithAccount:(NSString *)accountID
                         videoID:(NSString *)videoID
                      completion:(void (^)(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error))completionHandler;

- (NSString *)mediaSelectionDescription:(AVMediaSelection *)mediaSelection
                               URLAsset:(AVURLAsset *)URLAsset;

- (NSString *)mediaSelectionDescription:(AVMediaSelection *)mediaSelection
                      offlineVideoToken:(BCOVOfflineVideoToken)offlineVideoTokken;

- (void)updateOfflineTokens;

- (void)downloadVideo:(BCOVVideo *)video;

// Return license parameters as a mutable dictionary in case you want to add more params later
- (NSMutableDictionary *)generateLicenseParameters;

// Return download parameters as a mutable dictionary in case you want to add more params later
- (NSMutableDictionary *)generateDownloadParameters;

@end

NS_ASSUME_NONNULL_END
