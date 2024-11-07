//
//  GCKUICastContainerViewController+extensions.swift
//  BasicCastPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import GoogleCast


extension GCKUICastContainerViewController {

    open override var prefersStatusBarHidden: Bool {

        guard let navigationController = contentViewController as? UINavigationController,
              let viewController = navigationController.viewControllers.first else {
            return false
        }

        return viewController.prefersStatusBarHidden
    }
}
