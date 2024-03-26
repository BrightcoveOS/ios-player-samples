//
//  UITableViewCell+OfflinePlayer.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "UITableViewCell+OfflinePlayer.h"


@implementation UITableViewCell (OfflinePlayer)

- (UIViewController *)parentViewController
{
    SEL selector = @selector(presentViewController:animated:completion:);
    UIResponder *responder = self.nextResponder;

    while (responder && ![responder respondsToSelector:selector])
    {
        responder = responder.nextResponder;
    }

    return (UIViewController *)responder;
}

@end
