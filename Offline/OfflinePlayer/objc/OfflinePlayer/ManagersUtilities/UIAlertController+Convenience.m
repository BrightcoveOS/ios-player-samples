//
//  UIAlertController+Convenience.m
//  OfflinePlayer
//
//  Created by Jeremy Blaker on 10/29/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import "UIAlertController+Convenience.h"

@implementation UIAlertController (Convenience)

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               actionTitle:(NSString *)actionTitle
              inController:(UIViewController *)controller
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:actionTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller presentViewController:alert animated:YES completion:nil];
    });
}

@end
