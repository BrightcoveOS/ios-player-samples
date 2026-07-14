//
//  UITableViewCell+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import UIKit


extension UITableViewCell {

    var parentViewController: UIViewController? {

        var parentResponder: UIResponder? = self

        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }

        return nil
    }
}
