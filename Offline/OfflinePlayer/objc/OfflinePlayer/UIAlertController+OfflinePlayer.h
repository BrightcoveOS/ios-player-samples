//
//  UIAlertController+OfflinePlayer.h
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIAlertController (OfflinePlayer)

+ (void)showWithTitle:(NSString * _Nonnull)title
              message:(NSString * _Nonnull)message;

+ (void)showWithTitle:(NSString * _Nonnull)title
              message:(NSString * _Nonnull)message
          actionTitle:(NSString * _Nonnull)actionTitle
          cancelTitle:(NSString * _Nullable)cancelTitle
           completion:(nullable void (^)(void))completionBlock;

@end
