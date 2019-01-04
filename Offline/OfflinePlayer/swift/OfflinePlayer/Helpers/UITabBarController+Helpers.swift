//
//  UITabBarController+Helpers.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit

fileprivate enum ViewControllerIndex: NSInteger {
    case Video
    case Downloads
    case Settings
}

extension UITabBarController {
    
    func downloadsViewController() -> DownloadedVideoViewController? {
        guard let vc = viewController(atIndex: .Downloads) as? DownloadedVideoViewController else {
            return nil
        }
        return vc
    }
    
    func streamingViewController() -> StreamingVideoViewController? {
        guard let vc = viewController(atIndex: .Video) as? StreamingVideoViewController else {
            return nil
        }
        return vc
    }
    
    func settingsViewController() -> SettingsViewController? {
        guard let navController = viewController(atIndex: .Settings) as? UINavigationController, let vc = navController.viewControllers.first as? SettingsViewController else {
            return nil
        }
        return vc
    }
    
    private func viewController(atIndex index: ViewControllerIndex) -> UIViewController? {
        guard let viewControllers = self.viewControllers else {
            return nil
        }
        return viewControllers[index.rawValue]
    }
    
}
