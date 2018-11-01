//
//  SampleTabBarItemView.swift
//  AppleTV
//
//  Copyright © 2018 Brightcove. All rights reserved.
//

import BrightcovePlayerSDK

// This is a simple BCOVTVTabBarItemView subclass
// showing how to initialize the class and install a few buttons.
class SampleTabBarItemView: BCOVTVTabBarItemView {

    lazy var button1: UIButton = {
        let button = UIButton.init(type: .system)
        button.frame = CGRect.init(x:20, y:40, width:280, height:80)
        button.setTitle("Button 1", for:.normal)
        button.addTarget(self, action: #selector(buttonHandler), for: .primaryActionTriggered)
        return button
    }()
    
    lazy var button2: UIButton = {
        let button = UIButton.init(type: .system)
        button.frame = CGRect.init(x:340, y:40, width:280, height:80)
        button.setTitle("Button 2", for:.normal)
        button.addTarget(self, action: #selector(buttonHandler), for: .primaryActionTriggered)
        return button
    }()
    
    // MARK: - View Lifecycle

    override init(size: CGSize, playerView: BCOVTVPlayerView) {
        super.init(size: size, playerView: playerView)

        // Be sure to set a title for your tab bar item view
        title = "Sample"
        
        addSubview(button1)
        addSubview(button2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UI Interactions
    
    @objc func buttonHandler(button: UIButton) {
        guard let text = button.titleLabel?.text else {
            return
        }
        
        print("\(text) triggered")
        
        // Show a large label in the middle of the screen and fade it away.
        let fadingLabel: UILabel = {
            let label: UILabel = UILabel.init(frame: CGRect.init(x:0, y:0, width:840, height:140))
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
        
        UIView.animate(withDuration: 3.0, animations: {
            fadingLabel.alpha = 0.0
        }, completion: { (finished) in
            fadingLabel.removeFromSuperview()
        })
    }

}

// MARK: - UIFocusEnvironment overrides

extension SampleTabBarItemView {
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        
        // If we're moving focus down, don't let the focus guide wrap focus
        // back to the default button.
        // Makes for more natural focus navigation.
        if (context.focusHeading == UIFocusHeading.down) {
            
            if ((context.nextFocusedItem === button1) || (context.nextFocusedItem === button1)) {
                return false
            }
            
        }
        
        return true
    }
    
}
