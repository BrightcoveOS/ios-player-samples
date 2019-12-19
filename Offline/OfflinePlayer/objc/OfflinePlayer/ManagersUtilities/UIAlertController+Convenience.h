//
//  UIAlertController+Convenience.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/29/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (Convenience)

+ (void)showAlertWithTitle:(NSString * _Nullable)title
                   message:(NSString * _Nullable)message
               actionTitle:(NSString *)actionTitle
              inController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
