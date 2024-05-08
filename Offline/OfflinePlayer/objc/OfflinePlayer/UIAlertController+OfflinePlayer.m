//
//  UIAlertController+OfflinePlayer.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "UIAlertController+OfflinePlayer.h"


@implementation UIAlertController (OfflinePlayer)

+ (void)showWithTitle:(NSString * _Nonnull)title
              message:(NSString * _Nonnull)message
{
    [UIAlertController showWithTitle:title
                             message:message
                         actionTitle:@"OK"
                         cancelTitle:nil
                          completion:nil];
}

+ (void)showWithTitle:(NSString * _Nonnull)title
              message:(NSString * _Nonnull)message
          actionTitle:(NSString * _Nonnull)actionTitle
          cancelTitle:(NSString * _Nullable)cancelTitle
           completion:(nullable void (^)(void))completionBlock
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = ({
        [UIAlertAction actionWithTitle:actionTitle
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    });

    [alert addAction: action];

    if (cancelTitle)
    {
        UIAlertAction *cancelAction = ({
            [UIAlertAction actionWithTitle:cancelTitle
                                     style:UIAlertActionStyleCancel
                                   handler:nil];
        });

        [alert addAction:cancelAction];
    }

    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    UIViewController *rootViewController = window.rootViewController;

    if (rootViewController)
    {
        [rootViewController presentViewController:alert
                                         animated:true
                                       completion:nil];
    }
}

@end
