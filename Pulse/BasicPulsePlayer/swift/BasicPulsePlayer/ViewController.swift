//
//  ViewController.swift
//  BasicPulsePlayer
//
//  Created by Carlos Ceja on 2/21/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

import UIKit

import Pulse
import BrightcovePlayerSDK
import BrightcovePulse


struct PlaybackConfig
{
    static let PolicyKey = "insertyourservicepolicykeyhere"
    static let AccountID = "insertyouraccountidhere"
    static let VideoID = "insertyourvideoidhere"
}

struct PulseConfig
{
    static let PulseHost = "insertyourpulsehosthere"
}

class ViewController: UIViewController
{

    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var companionSlot: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var videoItems: [BCOVPulseVideoItem] =
    {
        var _videoItems = [BCOVPulseVideoItem]()
        if let path = Bundle.main.path(forResource: "Library", ofType: "json")
        {
            do
            {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
               
                if let jsonResult = jsonResult as? [[String : Any]]
                {
                    jsonResult.forEach { element in
                        
                        let item = BCOVPulseVideoItem.staticInit(dictionary: element)
                        _videoItems.append(item)

                    }
                }
            }
            catch
            {
                print("PlayerViewController Debug - Error retrieving library")
            }
        }
        
        return _videoItems;
    }()
    
    private lazy var playbackService: BCOVPlaybackService =
    {
        return BCOVPlaybackService(accountId: PlaybackConfig.AccountID, policyKey: PlaybackConfig.PolicyKey)
    }()
    
    private lazy var playerView: BCOVPUIPlayerView? =
    {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        
        // Create PlayerUI views with normal VOD controls.
        let controlView = BCOVPUIBasicControlView.withVODLayout()
        guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: controlView) else {
            return nil
        }
        
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to parent view
        self.videoContainer.addSubview(_playerView)
        
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ])
        
        return _playerView
    }()
    
    private lazy var pulseSessionProvider: BCOVPlaybackSessionProvider? =
    {
        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
        let contentMetadata = OOContentMetadata()
        
        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
        let requestSettings = OORequestSettings()
        
        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Enums/OOSeekMode.html
        requestSettings.seekMode = OOSeekMode.PLAY_ALL_ADS
        
        // Create a companion slot.
        let companionSlot = BCOVPulseCompanionSlot(view: self.companionSlot, width: 400, height: 100)!
        
        let pulseProperties = [
            kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self
        ]

        guard let _pulseSessionProvider = BCOVPlayerSDKManager.shared()?.createPulseSessionProvider(withPulseHost: PulseConfig.PulseHost, contentMetadata: contentMetadata, requestSettings: requestSettings, adContainer: self.playerView?.contentOverlayView, companionSlots: [companionSlot], upstreamSessionProvider: nil, options: pulseProperties) else {
            return nil
        }
        
        return _pulseSessionProvider
    }()
    
    private lazy var playbackController: BCOVPlaybackController? =
    {
        guard let _playbackController = BCOVPlayerSDKManager.shared()?.createPlaybackController(with: self.pulseSessionProvider, viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.isAutoPlay = true
        _playbackController.isAutoAdvance = true
        _playbackController.delegate = self
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
    private var video: BCOVVideo?
    
    private var videoItem: BCOVPulseVideoItem?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let _ = playerView
        let _ = playbackController
        
        requestVideo()
    }
    
    func requestVideo()
    {
        playbackService.findVideo(withVideoID: PlaybackConfig.VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable:Any]?, error: Error?) in
            
            if let video = video
            {
                self?.video = video
                
                self?.tableView.reloadData()
            }
            else
            {
                print("PlayerViewController Debug - Error retrieving video: \(error!.localizedDescription)")
            }
        }
    }

    // MARK: UI Styling
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

// MARK: - BCOVPlaybackControllerDelegate

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

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPulsePlaybackSessionDelegate
{
    func createSession(for video: BCOVVideo!, withPulseHost pulseHost: String!, contentMetdata contentMetadata: OOContentMetadata!, requestSettings: OORequestSettings!) -> OOPulseSession!
    {
        if pulseHost == nil
        {
            return nil
        }

        // Override the content metadata.
        contentMetadata.category = self.videoItem?.category
        contentMetadata.tags = self.videoItem?.tags
        contentMetadata.flags = self.videoItem?.flags

        // Override the request settings.
        requestSettings.linearPlaybackPositions = self.videoItem?.midrollPositions

        return OOPulse.session(with: contentMetadata, requestSettings: requestSettings)
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.videoContainer.isHidden = false;
        
        self.videoItem = self.videoItems[indexPath.item]

        self.playbackController?.setVideos([self.video] as NSFastEnumeration)
    }
}


// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return (self.video != nil) ? self.videoItems.count : 0;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
         return "Basic Pulse Player";
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)

        let item = videoItems[indexPath.item]

        cell.textLabel?.text = item.title

        let subtitle = item.category ?? ""

        cell.detailTextLabel?.text = "\(subtitle) \(item.tags?.joined(separator: ", ") ?? "")"

        return cell
    }
}


// MARK: - BCOVPulseVideoItem
class BCOVPulseVideoItem: NSObject
{
    var title: String? = ""
    var category: String? = ""
    var tags: Array<String>? = []
    var flags: Array<String>? = []
    var midrollPositions: Array<NSNumber>? = []
    
    static func staticInit(dictionary: [String : Any]) -> BCOVPulseVideoItem
    {
        let videoItem = BCOVPulseVideoItem()
        
        videoItem.title = dictionary["content-title"] as? String
        videoItem.category = dictionary["category"] as? String
        videoItem.tags = dictionary["tags"] as? Array<String>
        videoItem.flags = dictionary["flags"] as? Array<String>
        videoItem.midrollPositions = dictionary["midroll-positions"] as? Array<NSNumber>

        return videoItem
    }
}

