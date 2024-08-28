//
//  BCOVThumbnailManager.h
//  ReactNativePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>


#pragma mark -

@interface BCOVThumbnail : NSObject

@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) CMTime endTime;
@property (nonatomic, strong) NSURL *url;

@end


#pragma mark -

@interface BCOVThumbnailManager : NSObject

@property (nonatomic, readonly, strong) NSArray<BCOVThumbnail *> *thumbnails;

- (instancetype)initWithURL:(NSURL *)thumbnailURL;
- (NSURL *)thumbnailAtTime:(CMTime)time;

@end
