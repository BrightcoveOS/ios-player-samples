//
//  ViewController.swift
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import Pulse
import BrightcovePulse


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "6140448705001"

// Replace with your own Pulse Host
let kPulseHost = "https://bc-test.videoplaza.tv"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var companionSlotContainerView: UIView!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var headerTableView: UIView! {
        didSet {
            headerTableView.layer.borderColor = UIColor.init(white: 0.9,
                                                             alpha: 1.0).cgColor
            headerTableView.layer.borderWidth = 0.3
            headerTableView.addSubview(headerLabel)
        }
    }

    fileprivate lazy var headerLabel: UILabel = {
        let headerLabel = UILabel(frame: CGRect(x: 20,
                                                y: 0,
                                                width: headerTableView.frame.size.width - 40,
                                                height: headerTableView.frame.size.height))
        headerLabel.text = "Basic Pulse Player"
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .justified
        headerLabel.font = .boldSystemFont(ofSize: 16)
        headerLabel.textColor = .systemGray
        headerLabel.backgroundColor = .clear
        return headerLabel
    }()

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate lazy var playerView: BCOVPUIPlayerView? = {
        let options = BCOVPUIPlayerViewOptions()
        options.presentingViewController = self
        options.automaticControlTypeSelection = true

        guard let playerView = BCOVPUIPlayerView(playbackController: nil,
                                                 options: options,
                                                 controlsView: nil) else {
            return nil
        }

        playerView.delegate = self

        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.frame = videoContainerView.bounds
        videoContainerView.addSubview(playerView)

        return playerView
    }()

    fileprivate lazy var pulseSessionProvider: BCOVPulseSessionProvider? = {
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

        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
        let contentMetadata = OOContentMetadata()

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
        let requestSettings = OORequestSettings()

        let persistentId = ASIdentifierManager.shared().advertisingIdentifier.uuidString

        let pulsePlaybackSessionOptions = [
            kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
            kBCOVPulseOptionPulsePersistentIdKey: persistentId]

        let fps = sdkManager.createFairPlaySessionProvider(withAuthorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)
        guard let playerView,
              let contentOverlayView = playerView.contentOverlayView,
              let companionSlot = BCOVPulseCompanionSlot(view: companionSlotContainerView,
                                                         width: 400,
                                                         height: 100),
              let pulseSessionProvider = sdkManager.createPulseSessionProvider(withPulseHost: kPulseHost,
                                                                               contentMetadata: contentMetadata,
                                                                               requestSettings: requestSettings,
                                                                               adContainer: contentOverlayView,
                                                                               companionSlots: [companionSlot],
                                                                               upstreamSessionProvider: fps,
                                                                               options: pulsePlaybackSessionOptions) as? BCOVPulseSessionProvider else {
            return nil
        }

        return pulseSessionProvider
    }()

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        guard let playerView,
              let pulseSessionProvider else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: pulseSessionProvider,
                                                                     viewStrategy: nil)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true
        playbackController.allowsBackgroundAudioPlayback = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    fileprivate lazy var videoItems: [BCOVPulseVideoItem] = {
        // Load video library from Library.json into a JSON array.
        var videoItems = [BCOVPulseVideoItem]()
        if let path = Bundle.main.path(forResource: "Library",
                                       ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path),
                                    options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data,
                                                                  options: .mutableLeaves)
                if let jsonResult = jsonResult as? [[String: Any]] {
                    jsonResult.forEach { element in
                        let item = BCOVPulseVideoItem.staticInit(dictionary: element)
                        videoItems.append(item)
                    }
                }
            }
            catch {
                print("ViewController - Error retrieving library")
            }
        }

        return videoItems
    }()

    fileprivate var videoItem: BCOVPulseVideoItem?
    fileprivate var video: BCOVVideo?

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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestTrackingAuthorization),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc
    fileprivate func requestTrackingAuthorization() {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch (status) {
                    case .authorized:
                        print("Authorized Tracking Permission")
                    case .denied:
                        print("Denied Tracking Permission")
                    case .notDetermined:
                        print("Not Determined Tracking Permission")
                    case .restricted:
                        print("Restricted Tracking Permission")
                    @unknown default:
                        print("Default value Trackin Permission")
                }

                print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)")

                DispatchQueue.main.async { [self] in
                    // Tracking authorization completed.
                    // Start loading ads here.
                    requestContentFromPlaybackService()
                }

            }
        } else {
            requestContentFromPlaybackService()
        }

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: nil) {
            [self] (video: BCOVVideo?,
                    jsonResponse: Any?,
                    error: Error?) in
            guard let video else {
                if let error {
                    print("ViewController - Error retrieving video: \(error.localizedDescription)")
                }

                return
            }

            self.video = video
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
}


// MARK: - BCOVPlaybackControllerAdsDelegate

extension ViewController: BCOVPlaybackControllerAdsDelegate {

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didEnter adSequence: BCOVAdSequence!) {
        print("ViewController - Entering ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didExitAdSequence adSequence: BCOVAdSequence!) {
        print("ViewController - Exiting ad sequence")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didEnter ad: BCOVAd!) {
        print("ViewController - Entering ad")
    }

    func playbackController(_ controller: BCOVPlaybackController!,
                            playbackSession session: BCOVPlaybackSession!,
                            didExitAd ad: BCOVAd!) {
        print("ViewController - Exiting ad")
    }
}


// MARK: - BCOVPUIPlayerViewDelegate

extension ViewController: BCOVPUIPlayerViewDelegate {

    func playerView(_ playerView: BCOVPUIPlayerView!,
                    willTransitionTo screenMode: BCOVPUIScreenMode) {
        statusBarHidden = screenMode == .full
    }
}


// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPulsePlaybackSessionDelegate {

    func createSession(for video: BCOVVideo!,
                       withPulseHost pulseHost: String!,
                       contentMetadata: OOContentMetadata!, 
                       requestSettings: OORequestSettings!) -> OOPulseSession! {

        // Override the content metadata.
        contentMetadata.category = videoItem?.category
        contentMetadata.tags = videoItem?.tags

        // Override the request settings.
        requestSettings.linearPlaybackPositions = videoItem?.midrollPositions

        return OOPulse.session(with: contentMetadata,
                               requestSettings: requestSettings)
    }
}


// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, 
                   numberOfRowsInSection section: Int) -> Int {
        return videoItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let videoCell = tableView.dequeueReusableCell(withIdentifier: "VideoTableViewCell",
                                                      for: indexPath) as UITableViewCell

        let item = videoItems[indexPath.item]

        videoCell.textLabel?.text = item.title ?? ""
        videoCell.textLabel?.textColor = .black

        videoCell.detailTextLabel?.text = "\(item.category ?? "") \(item.tags?.joined(separator: ", ") ?? "")"
        videoCell.detailTextLabel?.textColor = .gray

        return videoCell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}


// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        guard let playbackController,
              let video else { return }

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

        videoItem = videoItems[indexPath.row]

        playbackController.setVideos([video])

        if let pulseSessionProvider,
           let extendSession = videoItem?.extendSession,
            extendSession {
            // Delay execution.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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

                pulseSessionProvider.requestSessionExtension(with: extendContentMetadata,
                                                             requestSettings: extendRequestSettings) {
                    print("Session was successfully extended. There are now midroll ads at 30th second.")
                }
            }
        }
    }
}
