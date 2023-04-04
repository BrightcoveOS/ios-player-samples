//
//  ViewController.swift
//  ViewStrategy
//
//  Created by Carlos Ceja.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


// ** Customize these values with your own account information **
struct PlaybackConfig
{
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let AccountID = "5434391461001"
    static let VideoID = "6140448705001"
}


class ViewController: UIViewController {
    
    @IBOutlet weak var videoContainer: UIView!
    
    private lazy var playbackService: BCOVPlaybackService = {
        
        return BCOVPlaybackService(accountId: PlaybackConfig.AccountID, policyKey: PlaybackConfig.PolicyKey)
        
    }()

    
    private lazy var playbackController: BCOVPlaybackController? = {
        
        let viewStrategy: BCOVPlaybackControllerViewStrategy = { (videoView, playbackController) -> UIView? in
            
            // Create some custom controls for the video view,
            // and compose both into a container view.
            let controlsAndVideoView = UIView(frame: CGRect.zero)

            let controlsView = ViewStrategyCustomControls(playbackController: playbackController)

            controlsAndVideoView.addSubview(videoView!)
            controlsAndVideoView.addSubview(controlsView)

            videoView?.frame = controlsAndVideoView.bounds

            playbackController?.add(controlsView)

            return controlsAndVideoView
        }
        
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(viewStrategy: viewStrategy) else {
            return nil;
        }
        
        _playbackController.isAutoPlay = true
        _playbackController.isAutoAdvance = true
        _playbackController.delegate = self
        
        _playbackController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to parent view
        self.videoContainer.addSubview(_playbackController.view)
        
        NSLayoutConstraint.activate([
            _playbackController.view.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            _playbackController.view.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            _playbackController.view.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            _playbackController.view.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ])
        
        return _playbackController
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestVideo()
    }
    
    func requestVideo()
    {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:PlaybackConfig.VideoID]
        playbackService.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            if let video = video
            {
                self?.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            else
            {
                print("ViewController Debug - Error retrieving video: \(error!.localizedDescription)")
            }
        })
    }
}

extension ViewController: BCOVPlaybackControllerDelegate
{
    func playbackController(_ controller: BCOVPlaybackController?, didAdvanceTo session: BCOVPlaybackSession?)
    {
        print("ViewController Debug - Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController?, playbackSession session: BCOVPlaybackSession?, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent?)
    {
        if let eventType = lifecycleEvent?.eventType
        {
            print("Event: \(eventType)")
        }
    }
}
