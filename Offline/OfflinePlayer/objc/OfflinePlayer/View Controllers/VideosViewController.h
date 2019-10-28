//
//  VideosViewController.h
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;

NS_ASSUME_NONNULL_BEGIN

@interface VideosViewController : UIViewController <UITabBarControllerDelegate>

// Cached video object data for quick display in the table view
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *videosTableViewData;

// Keeps track of all the estimated download sizes using the video Id as a key
@property (nonatomic, strong) NSMutableDictionary *estimatedDownloadSizeDictionary;

// Called by the download tab to indicate we need to update after a download deletion
- (void)didRemoveVideoFromTable:(BCOVOfflineVideoToken)brightcoveOfflineToken;

// Synchronize our table with data from the offline video manager
- (void)updateStatus;

// This demonstrates the "iOS 11 way" of downloading secondary tracks
// for your offline video.
- (void)downloadAllSecondaryTracksForOfflineVideoToken:(nonnull BCOVOfflineVideoToken)offlineVideoToken;

@end

NS_ASSUME_NONNULL_END

