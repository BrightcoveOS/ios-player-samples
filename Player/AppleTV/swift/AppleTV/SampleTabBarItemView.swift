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

    weak var button1: UIButton?
    weak var button2: UIButton?

    override init!(size: CGSize, playerView: BCOVTVPlayerView!) {
        super.init(size: size, playerView: playerView)

        // Be sure to set a title for your tab bar item view
        title = "Sample"
        
        // Create and install button 1
        button1 = {
            let button = UIButton.init(type: UIButtonType.system)
            button.frame = CGRect.init(x:20, y:40, width:280, height:80)
            button.setTitle("Button 1", for:UIControlState.normal)
            button.addTarget(self, action: #selector(self.buttonHandler), for: UIControlEvents.primaryActionTriggered)
            self.addSubview(button)
            return button
            }()

        // Create and install button 1
        button2 = {
            let button = UIButton.init(type: UIButtonType.system)
            button.frame = CGRect.init(x:340, y:40, width:280, height:80)
            button.setTitle("Button 2", for:UIControlState.normal)
            button.addTarget(self, action: #selector(self.buttonHandler), for: UIControlEvents.primaryActionTriggered)
            self.addSubview(button)
            return button
        }()
    }
    
    @objc func buttonHandler(button: UIButton) {
        if let text = button.titleLabel?.text {
            print("\(text) triggered")

            // Show a large label in the middle of the screen and fade it away.
            let fadingLabel: UILabel = {
                let label: UILabel = UILabel.init(frame: CGRect.init(x:0, y:0, width:840, height:140))
                label.clipsToBounds = true
                label.textColor = UIColor.red
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
            } ()

            UIView.animate(withDuration: 3.0, animations: {
                fadingLabel.alpha = 0.0
            }, completion: { (finished) in
                fadingLabel.removeFromSuperview()
            })
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIFocusEnvironment overrides

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        
        // If we're moving focus down, don't let the focus guide wrap focus
        // back to the default button.
        // Makes for more natural focus navigation.
        if (context.focusHeading == UIFocusHeading.down) {
            
            if #available(tvOS 10, *)
            {
                if ((context.nextFocusedItem === button1) || (context.nextFocusedItem === button1)) {
                    return false
                }
                
            } else {
                
                if ((context.nextFocusedView === button1) || (context.nextFocusedView === button1)) {
                    return false
                }
            }
        }
        
        return true
    }
}
