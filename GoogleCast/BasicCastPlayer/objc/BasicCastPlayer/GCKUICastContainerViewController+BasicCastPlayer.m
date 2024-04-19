//
//  GCKUICastContainerViewController+BasicCastPlayer.m
//  BasicCastPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "GCKUICastContainerViewController+BasicCastPlayer.h"


@implementation GCKUICastContainerViewController (BasicCastPlayer)

- (BOOL)prefersStatusBarHidden
{
    UINavigationController *navigationController = (UINavigationController *)self.contentViewController;
    UIViewController *viewController = navigationController.viewControllers.firstObject;

    return viewController.prefersStatusBarHidden;
}

@end
