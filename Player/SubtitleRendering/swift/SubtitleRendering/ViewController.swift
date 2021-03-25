//
//  ViewController.swift
//  SubtitleRendering
//
//  Created by Jeremy Blaker on 3/25/21.
//

import UIKit
import BrightcovePlayerSDK

// ** Customize these values with your own account information **
let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerAccountID = "5434391461001"
let kViewControllerVideoID = "5702141808001"

class ViewController: UIViewController {

    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var subtitlesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var playbackService: BCOVPlaybackService?
    private var playbackController: BCOVPlaybackController?
    private var playerView: BCOVPUIPlayerView?
    private var textTracks: [[String:Any]]?
    private var subtitleManager: SubtitleManager?
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subtitlesLabel.text = nil
        
        setup()
        
        requestContentFromPlaybackService()
    }
    
    // MARK: Setup
    
    private func setup() {
        playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
        
        setupPlaybackController()
        setupPlayerView()
    }
    
    private func setupPlaybackController() {
        playbackController = (BCOVPlayerSDKManager.shared().createPlaybackController())!
                
        playbackController?.delegate = self
        playbackController?.isAutoPlay = true
    }
    
    private func setupPlayerView() {
        guard let playerView = BCOVPUIPlayerView(playbackController: self.playbackController, options: nil, controlsView: BCOVPUIBasicControlView.withVODLayout()) else {
            return
        }

        self.videoContainer.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            playerView.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            playerView.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            playerView.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ])
        
        self.playerView = playerView
        
        // Hide built-in CC button
        let ccButton = playerView.controlsView.closedCaptionButton
        ccButton?.isHidden = true
        
        // Associate the playerView with the playback controller.
        playerView.playbackController = playbackController
    }
    
    // MARK: Helper Methods
    
    private func requestContentFromPlaybackService() {
        playbackService?.findVideo(withVideoID: kViewControllerVideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) -> Void in
            
            if let video = video {
                self?.gatherUsableTextTracks(video)
            } else {
                print("ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    private func gatherUsableTextTracks(_ video: BCOVVideo) {
        // We need to get an array of available text tracks
        // for this video. In this case we are going to use the
        // `text_tracks` array on this video's properties dictionary.
        // We're also going to set the `default` value of any of these
        // text tracks to ensure that AVPlayer doesn't select a track
        // automatically and attempt to render it itself.
        
        guard let allTextTracks = video.properties["text_tracks"] as? [[String:Any]] else {
            return
        }
        
        var usableTextTracks = [[String:Any]]()
        
        for textTrack in allTextTracks {
            guard let kind = textTrack["kind"] as? String else {
                continue
            }
            
            if kind == "captions" || kind == "subtitles" {
                var _textTrack = textTrack
                _textTrack["default"] = false
                usableTextTracks.append(_textTrack)
            }
        }
        
        textTracks = usableTextTracks
        tableView.reloadData()
        
        // If we have text tracks go ahead and
        // select the first one
        if let firstTextTrack = textTracks?.first {
            useTextTrack(firstTextTrack)
        }
        
        // Now update the BCOVVideo with our new text tracks array
        let updatedVideo = video.update({ (mutableVideo: BCOVMutableVideo) in
            if var props = mutableVideo.properties {
                props["text_tracks"] = usableTextTracks
                mutableVideo.properties = props
            }
        })
        
        playbackController?.setVideos([updatedVideo] as NSFastEnumeration)
    }
    
    private func useTextTrack(_ textTrack: [String:Any]) {
        // Look for an HTTPS source
        guard let sources = textTrack["sources"] as? [[String:Any]] else {
            return
        }
        
        var httpsSource: String?
        
        for srcDict in sources {
            if let src = srcDict["src"] as? String {
                if src.hasPrefix("https://") {
                    httpsSource = src
                    break
                }
            }
        }
        
        // If no HTTPS src is found fallback to default src
        let src = httpsSource ?? (textTrack["src"] as? String ?? "")
        
        guard let subtitleURL = URL(string: src) else {
            NSLog("Couldn't create URL from text track src");
            return
        }
        
        subtitleManager = SubtitleManager(url: subtitleURL)
    }
}

// MARK: UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if let textTrack = textTracks?[indexPath.row] {
                useTextTrack(textTrack)
            }
        } else {
            subtitleManager = nil
            subtitlesLabel.text = nil
        }
    }
    
}

// MARK: UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? textTracks?.count ?? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Text Tracks" : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextTrackCell")!
        
        if indexPath.section == 0 {
            if let textTrack = textTracks?[indexPath.row], let label = textTrack["label"] as? String, let srclang = textTrack["srclang"] as? String {
                cell.textLabel?.text = "\(label) (\(srclang))"
            }
        } else {
            cell.textLabel?.text = "Disable text track"
        }
        
        return cell
    }
    
}

// MARK: BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        session.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: DispatchQueue.main) { [weak self] (time: CMTime) in
            if let strongSelf = self, let subtitle = strongSelf.subtitleManager?.subtitleForTime(time) {
                strongSelf.subtitlesLabel.text = subtitle
            }
        }
    }
    
}
