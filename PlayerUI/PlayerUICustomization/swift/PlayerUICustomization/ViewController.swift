//
//  ViewController.swift
//  PlayerUICustomization
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
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


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "5702148954001"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var layoutLabel: UILabel!

    enum LayoutType: String {
        case Basic = "Built-in VOD Controls"
        case Simple = "Simple Custom Controls"
        case LiveDVR = "Built-in Live DVR Controls"
        case BasicLive = "Built-in Live Controls"
        case Complex = "Complex Layout"
        case `nil` = "nil Layout"

        func setup(forControlsView controlsView: BCOVPUIBasicControlView,
                   compactLayoutMaximumWidth: CGFloat) {

            lazy var controlLayout: BCOVPUIControlLayout? = nil

            switch self {
                case .Basic:
                    controlLayout = BCOVPUIControlLayout.basicVOD()
                case .Simple:
                    controlLayout = CustomLayouts.Simple()
                case .LiveDVR:
                    controlLayout = BCOVPUIControlLayout.basicLiveDVR()
                case .BasicLive:
                    controlLayout = BCOVPUIControlLayout.basicLive()
                case .Complex:
                    controlLayout = CustomLayouts.Complex()
                case .nil:
                    break
            }

            controlLayout?.compactLayoutMaximumWidth = compactLayoutMaximumWidth
            controlsView.layout = controlLayout
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
                    return .Complex
                case .Complex:
                    return .nil
                case .nil:
                    return .Basic
            }
        }
    }

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self

        // Make the controls linger on screen for a long time
        // so you can examine the controls.
        options.hideControlsInterval = 120

        // But hide and show quickly.
        options.hideControlsAnimationDuration = 0.2

        let controlsView = BCOVPUIBasicControlView.withVODLayout()
        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: controlsView) else {
            return nil
        }

        playerView.delegate = self

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)

        if playerView.controlsView != nil {
            playerView.controlsView.durationLabel.accessibilityLabelPrefix = "Total Time"
            playerView.controlsView.currentTimeLabel.accessibilityLabelPrefix = "As of now"
            playerView.controlsView.progressSlider.accessibilityLabel = "Timeline"

            playerView.controlsView.setButtonsAccessibilityDelegate(self)
        }

        return playerView
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        guard let sdkManager = BCOVPlayerSDKManager.sharedManager(),
              let authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil,
                                                         applicationId: nil) else {
            return nil
        }

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        guard let playerView,
              let playbackController = sdkManager.createPlaybackController(with: fps,
                                                                           viewStrategy: nil) else {
            return nil
        }

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var compactLayoutMaximumWidth: CGFloat = {
        return (view.frame.width + view.frame.height) / 2
    }()

    // Which layout are we displaying?
    fileprivate var layout: LayoutType = .Basic {
        didSet {
            layoutLabel.text = layout.rawValue

            guard let playerView else { return }

            layout.setup(forControlsView: playerView.controlsView,
                         compactLayoutMaximumWidth: compactLayoutMaximumWidth)
        }
    }

    fileprivate lazy var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        layout = .Basic

        requestContentFromPlaybackService()
    }

    override func motionBegan(_ motion: UIEvent.EventSubtype,
                              with event: UIEvent?) {
        super.motionBegan(motion, with: event)

        guard let playerView,
              let controlsView = playerView.controlsView,
              let hideableLayoutView = controlsView.layout.allLayoutItems.first(where: { ($0 as? BCOVPUILayoutView)?.tag == BCOVPUIViewTag.buttonPlayback.rawValue }) as? BCOVPUILayoutView else { return }

        // When the device is shaken, toggle the removal of the saved layout view.
        print("motionBegan - hiding/showing layout view")

        hideableLayoutView.isRemoved = !hideableLayoutView.isRemoved

        playerView.controlsView.setNeedsLayout()
    }

    @objc
    func handleButtonTap() {
        // When the "Tap Me" button is tapped, show a red label that fades quickly.
        guard let contentOverlayView = playerView?.contentOverlayView else { return }

        let label = UILabel(frame: contentOverlayView.frame)
        label.text = "Tapped!"
        label.textColor = .red
        label.font = UIFont.boldSystemFont(ofSize: 128)
        label.sizeToFit()
        contentOverlayView.addSubview(label)

        label.center = contentOverlayView.center

        UIView.animate(withDuration: 1, animations: {
            label.alpha = 0
        }) { (finished: Bool) in
            label.removeFromSuperview()
        }
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [playbackController] (video: BCOVVideo?,
                                  jsonResponse: [AnyHashable: Any]?,
                                  error: Error?) in
            guard let playbackController,
                  let video else {
                if let error {
                    print("ViewController - Error retrieving video: \(error.localizedDescription)")
                }

                return
            }

#if targetEnvironment(simulator)
            if video.usesFairPlay {
                // FairPlay doesn't work when we're running in a simulator,
                // so put up an alert.
                let alert = UIAlertController(title: "FairPlay Warning",
                                              message: """
                                               FairPlay only works on actual \
                                               iOS or tvOS devices.\n
                                               You will not be able to view \
                                               any FairPlay content in the \
                                               iOS or tvOS simulator.
                                               """,
                                              preferredStyle: .alert)

                alert.addAction(.init(title: "OK", style: .default))

                DispatchQueue.main.async { [self] in
                    present(alert, animated: true)
                }

                return
            }
#endif

            playbackController.setVideos([video] as NSFastEnumeration)
        }
    }

    @IBAction
    fileprivate func setNextLayout() {
        // Cycle through the various layouts.
        layout = layout.nextLayout()

        // Apply styles for specific layouts
        if let playerView {
            switch layout {
                case .Simple:
                    ControlViewStyles.Simple(forControlsView: playerView.controlsView)
                case .Complex:
                    ControlViewStyles.Complex(forControlsView: playerView.controlsView)
                default:
                    break
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController - Advanced to new session.")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            didCompletePlaylist playlist: NSFastEnumeration!) {
        // When the playlist completes, play it again.
        controller.setVideos(playlist)
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}


// MARK: - BCOVPUIButtonAccessibilityDelegate

extension ViewController: BCOVPUIButtonAccessibilityDelegate {

    func accessibilityLabel(for button: BCOVPUIButton!,
                            isPrimaryState: Bool) -> String! {
        switch button.tag {
            case BCOVPUIViewTag.buttonPlayback.rawValue:
                return (isPrimaryState ?
                        NSLocalizedString("Start Playback", comment: "") :
                            NSLocalizedString("Stop Playback", comment: ""))
            case BCOVPUIViewTag.buttonScreenMode.rawValue:
                return (isPrimaryState ?
                        NSLocalizedString("Enter Fullscreen", comment: "") :
                            NSLocalizedString("Exit Fullscreen", comment: ""))
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
