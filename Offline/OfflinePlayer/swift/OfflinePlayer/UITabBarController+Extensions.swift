//
//  UITabBarController+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


fileprivate enum ViewControllerIndex: NSInteger {
    case Videos
    case Downloads
    case Settings
}


extension UIViewController {

    var isVisible: Bool {
        return isViewLoaded && (view.window != nil)
    }
}


extension UITabBarController {

    fileprivate func viewController(at index: ViewControllerIndex) -> UIViewController? {
        guard let viewControllers,
              index.rawValue < viewControllers.count else {
            return nil
        }

        return viewControllers[index.rawValue]
    }

    var videosViewController: VideosViewController? {
        guard let viewController = viewController(at: .Videos) as? VideosViewController else {
            return nil
        }

        return viewController
    }

    var downloadsViewController: DownloadsViewController? {
        guard let viewController = viewController(at: .Downloads) as? DownloadsViewController else {
            return nil
        }

        return viewController
    }

    var settingsViewController: SettingsViewController? {
        guard let viewController = viewController(at: .Settings) as? SettingsViewController else {
            return nil
        }

        return viewController
    }

    func updateBadge() {
        guard let offlineManager = BCOVOfflineVideoManager.shared(),
              let offlineVideoStatusArray = offlineManager.offlineVideoStatus(),
              let downloadsViewController else {
            return
        }

        let filteredCount = offlineVideoStatusArray.filter({ $0.downloadState == .stateDownloading }).count

        downloadsViewController.tabBarItem.badgeValue = filteredCount > 0 ? "\(filteredCount)" : nil
    }
}
