//
//  UIAlertController+Helpers.swift
//  OfflinePlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    class func show(withTitle title: String, andMessage message: String) {
        UIAlertController.show(withTitle: title, message: message, actionTitle: "OK", cancelTitle: nil, completion: nil)
    }
    
    class func show(withTitle title: String, message: String, actionTitle: String, cancelTitle: String?, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action: UIAlertAction) in
            if let completion = completion {
                completion()
            }
        }))
        
        if let cancelTitle = cancelTitle {
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        }
        
        AppDelegate.current().tabBarController.present(alert, animated: true, completion: nil)
    }
    
}
