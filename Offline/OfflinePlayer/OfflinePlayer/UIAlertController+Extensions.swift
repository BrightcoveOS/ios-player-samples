//
//  UIAlertController+Extensions.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit


extension UIAlertController {

    class func showWith(title: String,
                        message: String) {
        UIAlertController.showWith(title: title,
                                   message: message,
                                   actionTitle: "OK",
                                   cancelTitle: nil,
                                   completion: nil)
    }

    class func showWith(title: String,
                        message: String,
                        actionTitle: String,
                        cancelTitle: String?,
                        completion: (() -> Void)?) {

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: actionTitle,
                                      style: .default) { (action: UIAlertAction) in
            if let completion {
                completion()
            }
        })

        if let cancelTitle {
            alert.addAction(UIAlertAction(title: cancelTitle,
                                          style: .cancel,
                                          handler: nil))
        }

        guard let window = UIApplication.shared.keyWindow,
              let rootViewController = window.rootViewController else {
            return
        }

        rootViewController.present(alert, animated: true)
    }
}
