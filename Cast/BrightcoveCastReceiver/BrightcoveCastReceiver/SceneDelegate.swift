//
//  SceneDelegate.swift
//  BrightcoveCastReceiver
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import UIKit


final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // UIKit creates the window and installs the initial view controller from
    // Main.storyboard, because the scene configuration in Info.plist declares
    // UISceneStoryboardFile. The property is required by UIWindowSceneDelegate.
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Wrap the storyboard content in the Cast container, so the mini
        // media controller shows at the bottom of the screen.
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            window?.rootViewController = appDelegate.castContainerViewController
        }
    }

}
