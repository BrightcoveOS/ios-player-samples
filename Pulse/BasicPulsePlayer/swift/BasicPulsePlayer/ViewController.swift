//
//  ViewController.swift
//  BasicPulsePlayer
//
//  Created by Carlos Ceja on 2/21/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

import AppTrackingTransparency
import UIKit

import Pulse

import BrightcovePlayerSDK
import BrightcovePulse


struct PlaybackConfig
{
    static let PolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let AccountID = "5434391461001"
    static let VideoID = "6140448705001"
}

struct PulseConfig
{
    // Replace with your own Pulse Host info:
    static let PulseHost = "https://bc-test.videoplaza.tv"
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
        
        // Create a companion slot.
        let companionSlot = BCOVPulseCompanionSlot(view: self.companionSlot, width: 400, height: 100)!

        let persistentId = UIDevice.current.identifierForVendor?.uuidString

        let pulseProperties = [
            kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
            kBCOVPulseOptionPulsePersistentIdKey: persistentId!
        ] as [String: Any]

        /**
         *  Initialize the Brightcove Pulse Plugin.
         *  Host:
         *      The host is derived from the "sub-domain” found in the Pulse UI and is formulated
         *      like this: `https://[sub-domain].videoplaza.tv`
         *  Device Container (kBCOVPulseOptionPulseDeviceContainerKey):
         *      The device container in Pulse is used for targeting and reporting purposes.
         *      This device container attribute is only used if you want to override the Pulse
         *      device detection algorithm on the Pulse ad server. This should only be set if normal
         *      device detection does not work and only after consulting our personnel.
         *      An incorrect device container value can result in no ads being served
         *      or incorrect ad delivery and reports.
         *  Persistent Id (kBCOVPulseOptionPulsePersistentIdKey):
         *      The persistent identifier is used to identify the end user and is the
         *      basis for frequency capping, uniqueness, DMP targeting information and
         *      more. Use Apple's advertising identifier (IDFA), or your own unique
         *      user identifier here.
         *
         *  Refer to:
         *  https://docs.invidi.com/r/INVIDI-Pulse-Documentation/Pulse-SDKs-parameter-reference
         */

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
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] (status: ATTrackingManager.AuthorizationStatus) in
                DispatchQueue.main.async {
                    self?.requestVideo()
                }
            }
        } else {
            requestVideo()
        }
    }
    
    func requestVideo()
    {
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:PlaybackConfig.VideoID]
        playbackService.findVideo(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (video: BCOVVideo?, jsonResponse: [AnyHashable: Any]?, error: Error?) in
            
            if let video = video
            {
                self?.video = video
                
                self?.tableView.reloadData()
            }
            else
            {
                print("PlayerViewController Debug - Error retrieving video: \(error!.localizedDescription)")
            }
        })
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
    func createSession(for video: BCOVVideo!, withPulseHost pulseHost: String!, contentMetadata: OOContentMetadata!, requestSettings: OORequestSettings!) -> OOPulseSession!
    {
        if pulseHost == nil
        {
            return nil
        }

        // Override the content metadata.
        contentMetadata.category = self.videoItem?.category
        contentMetadata.tags = self.videoItem?.tags

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

        if self.videoItem?.extendSession != nil {

            // Delay execution.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {

                /**
                 * You cannot request insertion points that have been requested already. For example,
                 * if you have already requested post-roll ads, then you cannot request them again.
                 * You can request additional mid-rolls, but only for cue points that have not been
                 * requested yet. For example, if you have already requested mid-rolls to show after 10 seconds
                 * and 30 seconds of video content playback, you can only request more mid-rolls for times that
                 * differ from 10 and 30 seconds.
                 */

                print("Request a session extension for midroll ads at 30th second.")

                let extendContentMetadata = OOContentMetadata()
                extendContentMetadata.tags = ["standard-midrolls"]

                let extendRequestSettings = OORequestSettings()
                extendRequestSettings.linearPlaybackPositions = [30]
                extendRequestSettings.insertionPointFilter = OOInsertionPointType.playbackPosition

                (self.pulseSessionProvider as? BCOVPulseSessionProvider)?.requestSessionExtension(with: extendContentMetadata, requestSettings: extendRequestSettings, success: {

                    print("Session was successfully extended. There are now midroll ads at 30th second.")

                })

            }

        }
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
        cell.textLabel?.textColor = UIColor.black

        cell.detailTextLabel?.text = "\(item.category ?? "") \(item.tags?.joined(separator: ", ") ?? "")"
        cell.detailTextLabel?.textColor = UIColor.gray

        return cell
    }
}


// MARK: - BCOVPulseVideoItem
class BCOVPulseVideoItem: NSObject
{
    var title: String?
    var category: String?
    var tags: Array<String>?
    var midrollPositions: Array<NSNumber>?
    var extendSession: Bool?
    
    static func staticInit(dictionary: [String : Any]) -> BCOVPulseVideoItem
    {
        let videoItem = BCOVPulseVideoItem()
        
        videoItem.title = dictionary["content-title"] as? String ?? ""
        videoItem.category = dictionary["category"] as? String
        videoItem.tags = dictionary["tags"] as? Array<String>
        videoItem.midrollPositions = dictionary["midroll-positions"] as? Array<NSNumber>
        videoItem.extendSession = dictionary["extend-session"] as? Bool

        return videoItem
    }
}

