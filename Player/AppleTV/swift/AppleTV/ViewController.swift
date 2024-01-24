//
//  ViewController.swift
//  AppleTV
//
//  Copyright © 2024 Brightcove. All rights reserved.
//

// This sample app shows how to set up and use the TV Player UI on tvOS.
// It also shows how to create a Custom Info View Controller with your own controls

import BrightcovePlayerSDK

fileprivate struct playbackConfig {
    static let policyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let accountID = "5434391461001"
    static let videoID = "6140448705001"
}

class ViewController: UIViewController
{
    @IBOutlet weak var videoContainerView: UIView!
    
    lazy var playerView: BCOVTVPlayerView? = {
        // Set ourself as the presenting view controller
        // so that tab bar panels can present other view controllers
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        
        // Create and add to the video container view
        guard let _playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }
        
        // Link the playback controller to the Player View
        _playerView.playbackController = playbackController
        
        videoContainerView.addSubview(_playerView)
        
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
        ])
        
        return _playerView
    }()
    
    lazy var playbackService: BCOVPlaybackService = {
        return BCOVPlaybackService(accountId: playbackConfig.accountID, policyKey: playbackConfig.policyKey)
    }()
    
    lazy var playbackController: BCOVPlaybackController? = {
        guard let _playbackController = BCOVPlayerSDKManager.shared().createPlaybackController() else {
            return nil
        }
        _playbackController.delegate = self
        _playbackController.isAutoAdvance = true
        _playbackController.isAutoPlay = true
        return _playbackController
    }()
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        createSampleInfoView()
        requestContentFromPlaybackService()
    }

    private func createSampleInfoView() {
        
        guard let playerView = playerView else {
            return
        }

        let sampleInfoVC = SampleInfoViewController(playerView: playerView)
        sampleInfoVC.preferredContentSize = CGSizeMake(0, 200)

        playerView.controlsView.customInfoViewControllers = [sampleInfoVC]
    }

    private func requestContentFromPlaybackService() {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:playbackConfig.videoID]
        playbackService.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            if let _video = video {
                //  since "isAutoPlay" is true, setVideos will begin playing the content
                self?.playbackController?.setVideos([_video] as NSArray)
            } else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
            }
            
        })
    }
  
}

// MARK: - UIFocusEnvironment overrides

extension ViewController {

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return (playerView != nil ? [ playerView! ] : [])
    }
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        NSLog("ViewController Debug - Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        NSLog("Event: %@", lifecycleEvent.eventType)
    }
    
}
