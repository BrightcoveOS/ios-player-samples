//
//  UIAlertController+Helpers.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    class func show(withTitle title: String, andMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        AppDelegate.current().tabBarController.present(alert, animated: true, completion: nil)
    }
    
}
