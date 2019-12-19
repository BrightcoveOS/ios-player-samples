//
//  SettingsAdapter.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/28/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsAdapter : NSObject

+ (long long int)bitrate;
+ (BOOL)purchaseLicenseType;
+ (unsigned long long)rentalDuration;

@end

NS_ASSUME_NONNULL_END
