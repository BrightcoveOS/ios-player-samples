//
//  SettingsAdapter.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/28/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "SettingsAdapter.h"
#import "InterfaceManager.h"
#import "SettingsViewController.h"

@implementation SettingsAdapter

+ (long long int)bitrate
{
    return [InterfaceManager.sharedInstance settingsViewController].bitrate;
}

+ (BOOL)purchaseLicenseType
{
    return [InterfaceManager.sharedInstance settingsViewController].purchaseLicenseType;
}

+ (unsigned long long)rentalDuration
{
    return [InterfaceManager.sharedInstance settingsViewController].rentalDuration;
}

@end
