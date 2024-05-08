//
//  GCKUICastContainerViewController+BrightcoveCastReceiver.m
//  BrightcoveCastReceiver
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "GCKUICastContainerViewController+BrightcoveCastReceiver.h"


@implementation GCKUICastContainerViewController (BrightcoveCastReceiver)

- (BOOL)prefersStatusBarHidden
{
    UINavigationController *navigationController = (UINavigationController *)self.contentViewController;
    UIViewController *viewController = navigationController.viewControllers.firstObject;

    return viewController.prefersStatusBarHidden;
}

@end
