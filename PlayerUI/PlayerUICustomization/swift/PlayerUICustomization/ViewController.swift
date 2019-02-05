//
//  ViewController.swift
//  PlayerUICustomization
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//
// This sample app shows you how to use the PlayerUI control customization.
// The PlayerUI code is now integrated in the BrightcovePlayerSDK module, so you
// can begin using it without importing any other modules besides the BrightcovePlayerSDK.
//
// There are five sample layouts. When you run the app, you can dynamically
// switch between all the layouts to see them in action.
//
// 1 - Built-in VOD Controls
// This is a Brightcove-supplied built-in layout for displaying normal controls
// with regular video on demand.
// AirPlay and Subtitle/Audio Track controls are included, but only visible
// when they are needed.
//
// 2 - Simple Custom Controls
// This is a simple control layout with only four elements.
// The layout switches from one line to two lines when moving from landscape
// to portrait orientation.
// The code for setting up this layout manually is shown.
//
// 3 - Built-in Live Controls
// This is a Brightcove-supplied built-in layout for displaying normal controls
// with a live video stream.
// AirPlay and Subtitle/Audio Track controls are included, but only visible
// when they are needed.
//
// 4 - Built-in Live DVR Controls
// This is a Brightcove-supplied built-in layout for displaying normal controls
// with a live DVR video stream.
// The Live indicator turns green when you are watching the live edge
// of the video stream. It can be tapped at any time to view the most recent
// part of the video feed.
// AirPlay and Subtitle/Audio Track controls are included, but only visible
// when they are needed.
//
// 5 - Complex Layout
// This is a highly customized layout showing many of the features of
// PlayerUI customization.
// This layout has more items than most, and is designed for iPads.
// For iPhones, a similar layout should be split into shorter rows in portrait
// orientation.
// The code for setting up this layout manually is shown.
// Features include:
//   - Custom colors for text and sliders
//   - Custom font for text labels
//   - Single line of controls in portrait orientation; three lines of controls
//     in landscape orientation
//   - UIImage-based logos added to different layout views
//   - Custom label added to a view
//   - Custom control (with action) added to a control
//   - UIImage view overlapping multiple rows
//   - Layout views using custom elasticities
//   - The play/pause button can be hidden/shown by shaking the device
//     (see motionBegan:withEvent:)
//   - User markers are set on the slider
// AirPlay and Subtitle/Audio Track controls are included, but only visible
//
// 6 - Nil Controls
// You can set the controls layout to nil; this essentially removes
// all playback controls.
//

import UIKit
import BrightcovePlayerSDK

// ** Customize these values with your own account information **
struct PlayerUIConstants {
    static let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    static let AccountID = "3636334163001"
    static let VideoID = "3666678807001"
}

class ViewController: UIViewController {

    enum LayoutType: String {
        case Basic = "Built-in VOD Controls"
        case Simple = "Simple Custom Controls"
        case LiveDVR = "Built-in Live DVR Controls"
        case BasicLive = "Built-in Live Controls"
        case ComplexCustom = "Complex Layout"
        case Nil = "Nil layout"
        
        func setup(forControlsView controlsView: BCOVPUIBasicControlView, layoutLabel: UILabel, compactLayoutMaximumWidth: CGFloat) -> BCOVPUILayoutView? {
            layoutLabel.text = self.rawValue
            
            var controlLayout: BCOVPUIControlLayout?
            var layoutView: BCOVPUILayoutView?
            
            switch self {
            case .Basic:
                controlLayout = BCOVPUIControlLayout.basicVOD()
            case .Simple:
                let (_controlLayout, _layoutView) = CustomLayouts.Simple(forControlsView: controlsView)
                controlLayout = _controlLayout
                layoutView = _layoutView
            case .LiveDVR:
                controlLayout = BCOVPUIControlLayout.basicLiveDVR()
            case .BasicLive:
                controlLayout = BCOVPUIControlLayout.basicLive()
            case .ComplexCustom:
                let (_controlLayout, _layoutView) = CustomLayouts.Complex(forControlsView: controlsView)
                controlLayout = _controlLayout
                layoutView = _layoutView
            case .Nil:
                break
            }
            
            controlLayout?.compactLayoutMaximumWidth = compactLayoutMaximumWidth
            
            controlsView.layout = controlLayout
            
            return layoutView
        }
        
        func nextLayout() -> LayoutType {
            switch self {
            case .Basic:
                return .Simple
            case .Simple:
                return .LiveDVR
            case .LiveDVR:
                return .BasicLive
            case .BasicLive:
                return .ComplexCustom
            case .ComplexCustom:
                return .Nil
            case .Nil:
                return .Basic
            }
        }
    }
    
    @IBOutlet var videoView: UIView!
    @IBOutlet var layoutLabel: UILabel!
    
    lazy var playbackService: BCOVPlaybackService = {
       return BCOVPlaybackService(accountId: PlayerUIConstants.AccountID, policyKey: PlayerUIConstants.PlaybackServicePolicyKey)
    }()
    lazy var playbackController: BCOVPlaybackController? = {
        guard let manager = BCOVPlayerSDKManager.shared(), let controller = manager.createPlaybackController() else {
            return nil
        }
        controller.delegate = self
        controller.isAutoAdvance = true
        controller.isAutoPlay = true
        return controller
    }()
    lazy var compactLayoutMaximumWidth: CGFloat = {
       return (view.frame.width + view.frame.height) / 2
    }()
    
    // Which layout are we displaying?
    var layout: LayoutType = .Basic
    // This stores a ref to a view we want to show/hide on demand.
    var hideableLayoutView: BCOVPUILayoutView?
    // PlayerUI's Player View
    var playerView: BCOVPUIPlayerView?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlayer()
        updateLayout()
        accessibilitySetup()
    }
    
    // MARK: - Helper Methods
    
    private func configurePlayer() {
        print("Configure the Player View")
        
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        
        // Make the controls linger on screen for a long time
        // so you can examine the controls.
        options.hideControlsInterval = 120
        
        // But hide and show quickly.
        options.hideControlsAnimationDuration = 0.2
        
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        
        playerView = BCOVPUIPlayerView(playbackController: playbackController, options: options, controlsView: controlView)
        
        guard let playerView = playerView else {
            return
        }

        playerView.delegate = self
        
        // Add BCOVPUIPlayerView to video view.
        videoView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.videoView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: self.videoView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: self.videoView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.videoView.bottomAnchor)
        ])
        
        print("Request Content from the Video Cloud")
        playbackService.findVideo(withVideoID: PlayerUIConstants.VideoID, parameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            if let video = video, let strongSelf = self {
                strongSelf.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            
            if let error = error {
                print("ViewController Debug - Error retrieving video playlist: \(error.localizedDescription)")
            }
            
        })
    }
    
    private func updateLayout() {
        if let playerView = playerView {
            hideableLayoutView = layout.setup(forControlsView: playerView.controlsView, layoutLabel: layoutLabel, compactLayoutMaximumWidth: compactLayoutMaximumWidth)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction private func setNextLayout() {
        // Cycle through the various layouts.
        layout = layout.nextLayout()
        
        // Apply the new layout
        updateLayout()
        
        // Apply styles for specific layouts
        if let playerView = playerView {
            switch layout {
            case .ComplexCustom:
                ControlViewStyles.Complex(forControlsView: playerView.controlsView)
            default:
                break
            }
        }
        
    }
    
    // MARK: - Misc
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // When the device is shaken, toggle the removal of the saved layout view.
        print("motionBegan - hiding/showing layout view")
        
        guard let hideableLayoutView = hideableLayoutView, let playerView = playerView else {
            return
        }
        
        hideableLayoutView.isRemoved = !hideableLayoutView.isRemoved
        
        playerView.controlsView.setNeedsLayout()
    }
    
    @objc func handleButtonTap(button: UIButton) {
        // When the "Tap Me" button is tapped, show a red label that fades quickly.
        guard let playerView = playerView else {
            return
        }
        let label = UILabel(frame: playerView.frame)
        label.text = "Tapped!"
        label.textColor = .red
        label.font = UIFont.boldSystemFont(ofSize: 128)
        label.sizeToFit()
        playerView.addSubview(label)
        label.center = playerView.center
        
        UIView.animate(withDuration: 1, animations: {
            label.alpha = 0
        }) { (finished: Bool) in
            label.removeFromSuperview()
        }
    }
    
    private func accessibilitySetup() {
        playerView?.controlsView.setButtonsAccessibilityDelegate(self)
        
        playerView?.controlsView.durationLabel.accessibilityLabelPrefix = "Total Time";
        playerView?.controlsView.currentTimeLabel.accessibilityLabelPrefix = "As of now";
        playerView?.controlsView.progressSlider.accessibilityLabel = "Timeline";
        playbackController?.view.accessibilityHint = "Double tap to show or hide controls";
    }

}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didCompletePlaylist playlist: NSFastEnumeration!) {
        // When the playlist completes, play it again.
        playbackController?.setVideos(playlist)
    }
    
}

// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {
    
}

// MARK: - BCOVPUIButtonAccessibilityDelegate

extension ViewController: BCOVPUIButtonAccessibilityDelegate {
    
    func accessibilityLabel(for button: BCOVPUIButton!, isPrimaryState: Bool) -> String! {
        switch button.tag {
        case BCOVPUIViewTag.buttonPlayback.rawValue:
            return isPrimaryState ? NSLocalizedString("Start Playback", comment: "") : NSLocalizedString("Stop Playback", comment: "")
        case BCOVPUIViewTag.buttonScreenMode.rawValue:
            return isPrimaryState ? NSLocalizedString("Enter Fullscreen", comment: "") : NSLocalizedString("Exit Fullscreen", comment: "")
        case BCOVPUIViewTag.buttonJumpBack.rawValue:
            return nil
        case BCOVPUIViewTag.buttonClosedCaption.rawValue:
            return nil
        case BCOVPUIViewTag.buttonVideo360.rawValue:
            return nil
        case BCOVPUIViewTag.buttonPreferredBitrate.rawValue:
            return nil
        default:
            return nil
        }
    }
    
}

