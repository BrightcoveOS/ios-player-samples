//
//  VideoViewController.swift
//  VerticalPlayer
//
//  Created by Jeremy Blaker on 9/27/23.
//

import UIKit
import BrightcovePlayerSDK

class VideoViewController: UIViewController {
    
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var videoDescriptionLabel: UILabel! {
        didSet {
            videoDescriptionLabel.text = nil
        }
    }
    @IBOutlet weak var playIconView: UIImageView!
    @IBOutlet weak var posterView: UIImageView!
    
    var playbackController: BCOVPlaybackController?
    var video: BCOVVideo?
    var didSetVideo = false

    var playbackGesture: UITapGestureRecognizer?
    
    weak var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }

    func setUp() {
        setUpPlaybackController()
        setUpGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if didSetVideo {
            playbackController?.play()
        } else {
            if let video = video {
                displayVideo(video)
                didSetVideo = true
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playbackController?.pause()
    }
    
    func setUpPlayerView() {
        guard let playerView = BCOVPUIPlayerView(playbackController: playbackController, options: nil, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return
        }
        
        // Install in the container view and match its size.
        videoContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            playerView.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
        ])
    }
    
    func setUpPlaybackController() {
        guard let playbackController = (BCOVPlayerSDKManager.shared().createPlaybackController()) else {
            return
        }
        playbackController.delegate = self
        playbackController.isAutoPlay = true
        
        videoContainerView.addSubview(playbackController.view)
        playbackController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playbackController.view.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            playbackController.view.rightAnchor.constraint(equalTo: videoContainerView.rightAnchor),
            playbackController.view.leftAnchor.constraint(equalTo: videoContainerView.leftAnchor),
            playbackController.view.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
        ])
        
        self.playbackController = playbackController
    }
    
    func setUpGestures() {
        let playbackGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        videoContainerView.addGestureRecognizer(playbackGesture)
        self.playbackGesture = playbackGesture
    }
    
    func displayVideo(_ video: BCOVVideo) {
        fetchPoster()
        playbackController?.setVideos([video] as NSFastEnumeration)
        guard let videoDescription = video.properties[kBCOVVideoPropertyKeyDescription] as? String else {
            videoDescriptionLabel.text = ""
            return
        }
        videoDescriptionLabel.text = videoDescription
    }
    
    func fetchPoster() {
        guard let video = video, let posterURLStr = video.properties[kBCOVVideoPropertyKeyPoster] as? String, let posterURL = URL(string: posterURLStr) else {
            return
        }
        let urlRequest = URLRequest(url: posterURL)
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let data = data else {
                return
            }
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self?.posterView.image = image
            }
        }
        task.resume()
    }
    
    // MARK: - Button Actions
    
    @IBAction func handleShareButton(_ button: UIBarButtonItem) {
        guard let video = video, let videoName = video.properties[kBCOVVideoPropertyKeyName] as? String, let posterURLStr = video.properties[kBCOVVideoPropertyKeyPoster] as? String, let posterURL = URL(string: posterURLStr) else {
            return
        }
        let request = URLRequest(url: posterURL)
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let data = data else {
                return
            }
            let message = "Check out this video, \"\(videoName)\", it's awesome."
            var items: [Any] = [message]
            if let posterImage = UIImage(data: data) {
                items = [message, posterImage]
            }
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                self.present(activityVC, animated: true)
            }
        }
        task.resume()
    }
    
    // MARK: - Gesture Actions
    
    @objc
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        if player?.rate == 0 {
            playbackController?.play()
            UIView.animate(withDuration: 0.25) {
                self.playIconView.alpha = 0.0
            }
        } else {
            playbackController?.pause()
            UIView.animate(withDuration: 0.25) {
                self.playIconView.alpha = 1.0
            }
        }
    }
}

extension VideoViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        session.playerLayer.videoGravity = .resizeAspectFill
        player = session.player
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventPlaybackLikelyToKeepUp {
            UIView.animate(withDuration: 0.25) {
                self.posterView.alpha = 0.0
            }
        }
        if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd {
            playIconView.isHidden = false
        }
    }
}

