//
//  SampleInfoViewController.swift
//  AppleTV
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

final class SampleInfoViewController: UIViewController, BCOVPlaybackSessionConsumer {

    fileprivate weak var playerView: BCOVTVPlayerView?

    fileprivate lazy var button1: UIButton = {
        let button = UIButton.init(type: .system)
        button.frame = CGRect.init(x:20, y:40, width:280, height:80)
        button.setTitle("Button 1", for:.normal)
        button.addTarget(self,
                         action: #selector(buttonHandler),
                         for: .primaryActionTriggered)
        return button
    }()

    fileprivate lazy var button2: UIButton = {
        let button = UIButton.init(type: .system)
        button.frame = CGRect.init(x:340, y:40, width:280, height:80)
        button.setTitle("Button 2", for:.normal)
        button.addTarget(self,
                         action: #selector(buttonHandler),
                         for: .primaryActionTriggered)
        return button
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(playerView: BCOVTVPlayerView) {
        super.init(nibName: nil, bundle: nil)
        self.playerView = playerView

        title = "Sample"

        view.addSubview(button1)
        view.addSubview(button2)
    }

    @objc
    fileprivate func buttonHandler(button: UIButton) {
        guard let playerView,
              let text = button.titleLabel?.text else {
            return
        }

        print("\(text) triggered")

        // Show a large label in the middle of the screen and fade it away.
        let fadingLabel: UILabel = {
            let label: UILabel = .init(frame: CGRect.init(x:0, y:0, width:840, height:140))
            label.clipsToBounds = true
            label.textColor = .red
            label.textAlignment = NSTextAlignment.center
            label.backgroundColor = UIColor.init(white: 0.0, alpha: 0.4)
            label.font = UIFont.boldSystemFont(ofSize: 72.0)
            label.text = "\(text) Clicked"
            label.center = playerView.center
            label.layer.cornerRadius = button.frame.size.height * 0.8
            label.layer.borderColor = UIColor.white.cgColor
            label.layer.borderWidth = 2.0
            playerView.overlayView.addSubview(label)
            return label
        }()

        UIView.animate(withDuration: 3.0) {
            fadingLabel.alpha = 0.0
        } completion: { _ in
            fadingLabel.removeFromSuperview()
        }
    }
}
