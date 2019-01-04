//
//  VideosViewController.h
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@import BrightcovePlayerSDK;

typedef enum
{
    eVideoStateOnlineOnly = 0,
    eVideoStateDownloadable = 1,
    eVideoStateDownloading = 2,
    eVideoStatePaused = 3,
    eVideoStateCancelled = 4,
    eVideoStateDownloaded = 5,
    eVideoStateError = 6
    
} VideoState;

@interface VideosViewController : UIViewController <BCOVOfflineVideoManagerDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong, nonnull) BCOVOfflineVideoManager *offlineVideoManager;
@property (nonatomic, strong, nonnull) id<BCOVPlaybackController> playbackController;

// List of all the currently downloaded videos (as offline video tokens)
@property (nonatomic, nonnull) NSArray<BCOVOfflineVideoToken> *offlineVideoTokenArray;

// The parent tab bar controller for all three primary view controllers
@property (nonatomic, nonnull) UITabBarController *tabBarController;

// Cached video object data for quick display in the table view
@property (nonatomic, nonnull) NSMutableArray<NSMutableDictionary *> *videosTableViewData;

// Keeps track of all the estimated download sizes using the video Id as a key
@property (nonatomic, nonnull) NSMutableDictionary *estimatedDownloadSizeDictionary;

// Keeps track of all the final download sizes using the offline video token as a key
@property (nonatomic, nonnull) NSMutableDictionary *downloadSizeDictionary;

// Use a newly retrieved playlist in the table
- (void)usePlaylist:(nonnull NSArray *)playlist;

// Return license parameters as a mutable dictionary in case you want to add more params later
- (nonnull NSMutableDictionary *)generateLicenseParameters;

// Return download parameters as a mutable dictionary in case you want to add more params later
- (nonnull NSMutableDictionary *)generateDownloadParameters;

// Called by the download tab to indicate we need to update after a download deletion
- (void)didRemoveVideoFromTable:(nonnull BCOVOfflineVideoToken)brightcoveOfflineToken;

// Synchronize our table with data from the offline video manager
- (void)updateStatus;

// This demonstrates the "iOS 11 way" of downloading secondary tracks
// for your offline video.
- (void)downloadAllSecondaryTracksForOfflineVideoToken:(nonnull BCOVOfflineVideoToken)offlineVideoToken;


// Give other controllers a way to retrieve videos.
// Used for FairPlay license renewal.
- (void)retrieveVideoWithAccount:(NSString *)accountID
                         videoID:(NSString *)videoID
                      completion:(void (^)(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error))completionHandler;

@end


@interface VideoCell : UITableViewCell

@property (nonatomic, nonnull) UIButton *statusButton;

- (void)setStateImage:(VideoState)state;

@end

extern VideosViewController * _Nonnull gVideosViewController;

