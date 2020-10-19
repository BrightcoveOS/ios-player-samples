//
//  UIAlertController+Convenience.h
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/29/19.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIAlertController (Convenience)

+ (void)showAlertWithTitle:(NSString * _Nullable)title
                   message:(NSString * _Nullable)message
               actionTitle:(NSString * _Nullable)actionTitle
              inController:(UIViewController * _Nullable)controller;

+ (void)showAlertWithTitle:(NSString * _Nullable)title
                   message:(NSString * _Nullable)message
               actionTitle:(NSString * _Nullable)actionTitle
               cancelTitle:(NSString * _Nullable)cancelTitle
               inController:(UIViewController * _Nullable)controller
                 completion:(nullable void (^)(void))completionBlock;

@end
