//
//  VideoViewController.swift
//  VerticalPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


final class VideoViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView! {
        didSet {
            videoContainerView.addGestureRecognizer(playbackGesture)
        }
    }

    @IBOutlet fileprivate weak var videoDescriptionLabel: UILabel! {
        didSet {
            videoDescriptionLabel.text = nil
        }
    }

    @IBOutlet fileprivate weak var playIconView: UIImageView!

    @IBOutlet fileprivate weak var posterView: UIImageView!

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: fps,
                                                                           viewStrategy: nil)

        // Prevents the Brightcove SDK from making an unnecessary AVPlayerLayer
        // since the AVPlayerViewController already makes one
        playbackController.options = [ kBCOVAVPlayerViewControllerCompatibilityKey: true ]

        playbackController.view.frame = videoContainerView.bounds
        playbackController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoContainerView.addSubview(playbackController.view)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        return playbackController
    }()

    fileprivate lazy var playbackGesture: UITapGestureRecognizer = {
        let playbackGesture = UITapGestureRecognizer(target: self,
                                                     action: #selector(handleTap(_:)))
        return playbackGesture
    }()

    fileprivate lazy var didSetVideo = false

    fileprivate weak var player: AVPlayer?

    weak var video: BCOVVideo?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if didSetVideo {
            guard let playbackController else { return }
            playbackController.play()
            playIconView.alpha = 0.0
        } else {
            guard let video else { return }

            if let posterURLStr = video.properties[BCOVVideo.PropertyKeyPoster] as? String,
               let posterURL = URL(string: posterURLStr) {
                let urlRequest = URLRequest(url: posterURL)
                URLSession.shared.dataTask(with: urlRequest) {
                    (data: Data?, response: URLResponse?, error: Error?) in
                    if let error {
                        print(error.localizedDescription)
                        return
                    }

                    guard let data,
                          let image = UIImage(data: data) else { return }

                    DispatchQueue.main.async { [self] in
                        posterView.image = image
                    }
                }.resume()
            }

            videoDescriptionLabel.text = video.properties[BCOVVideo.PropertyKeyDescription] as? String ?? ""

            if let playbackController {
                playbackController.setVideos([video])

                didSetVideo = true
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let playbackController else { return }
        playbackController.pause()
    }

    @IBAction
    fileprivate func handleShareButton(_ button: UIBarButtonItem) {
        guard let video,
              let videoName = video.properties[BCOVVideo.PropertyKeyName] as? String,
              let posterURLStr = video.properties[BCOVVideo.PropertyKeyPoster] as? String,
              let posterURL = URL(string: posterURLStr) else {
            return
        }

        let request = URLRequest(url: posterURL)

        URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            guard let data else { return }
            let message = "Check out this video, \"\(videoName)\", it's awesome."
            var items: [Any] = [message]
            if let posterImage = UIImage(data: data) {
                items = [message, posterImage]
            }
            DispatchQueue.main.async { [self] in
                let activityVC = UIActivityViewController(activityItems: items,
                                                          applicationActivities: nil)
                present(activityVC, animated: true)
            }
        }.resume()
    }

    @IBAction
    fileprivate func handleTap(_ recognizer: UITapGestureRecognizer) {
        if player?.rate == 0 {
            playbackController?.play()
            UIView.animate(withDuration: 0.25) { [self] in
                playIconView.alpha = 0.0
            }
        } else {
            playbackController?.pause()
            UIView.animate(withDuration: 0.25) { [self] in
                playIconView.alpha = 1.0
            }
        }
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension VideoViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, 
                            didAdvanceTo session: BCOVPlaybackSession!) {
        session.playerLayer.videoGravity = .resizeAspectFill
        player = session.player
        print("ViewController - Advanced to new session.")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, 
                            playbackSession session: BCOVPlaybackSession!,
                            didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        if kBCOVPlaybackSessionLifecycleEventPlaybackLikelyToKeepUp == lifecycleEvent.eventType {
            UIView.animate(withDuration: 0.25) { [self] in
                posterView.alpha = 0.0
            }
        }

        if kBCOVPlaybackSessionLifecycleEventEnd == lifecycleEvent.eventType {
            playIconView.alpha = 1.0
        }

        if kBCOVPlaybackSessionLifecycleEventFail == lifecycleEvent.eventType,
           let error = lifecycleEvent.properties["error"] as? NSError {
            // Report any errors that may have occurred with playback.
            print("ViewController - Playback error: \(error.localizedDescription)")
        }
    }
}
