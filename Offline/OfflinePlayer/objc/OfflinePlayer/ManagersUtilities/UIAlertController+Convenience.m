//
//  UIAlertController+Convenience.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/29/19.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import "UIAlertController+Convenience.h"

@implementation UIAlertController (Convenience)

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               actionTitle:(NSString *)actionTitle
              inController:(UIViewController *)controller
{
    [UIAlertController showAlertWithTitle:title message:message actionTitle:actionTitle cancelTitle:nil inController:controller completion:nil];
}

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               actionTitle:(NSString *)actionTitle
               cancelTitle:(NSString *)cancelTitle
              inController:(UIViewController *)controller
                completion:(nullable void (^)(void))completionBlock
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *primaryAction = [UIAlertAction actionWithTitle:actionTitle
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        if (completionBlock)
        {
            completionBlock();
        }
    }];
    
    [alert addAction:primaryAction];
    
    if (cancelTitle)
    {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        
        [alert addAction:cancelAction];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller presentViewController:alert animated:YES completion:nil];
    });
}

@end
