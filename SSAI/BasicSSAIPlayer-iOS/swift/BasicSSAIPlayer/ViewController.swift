//
//  ViewController.swift
//  BasicSSAIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit
import BrightcoveSSAI
//import OMSDK_Brightcove
//import ProgrammaticAccessLibrary


// Customize these values with your own account information
// Add your Brightcove account and video information here.
let kAccountId = "5434391461001"
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kVideoId = "5702141808001"
let kAdConfigId = "0e0bbcd1-bba0-45bf-a986-1288e5f9fc85"
let kVMAPURL = "https://sdks.support.brightcove.com/assets/ads/ssai/sample-vmap.xml"


final class ViewController: UIViewController {

    @IBOutlet fileprivate weak var videoContainerView: UIView!
    @IBOutlet fileprivate weak var companionSlotContainerView: UIView!

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

    fileprivate lazy var playbackController: BCOVPlaybackController? = {
        let sdkManager = BCOVPlayerSDKManager.sharedManager()
        let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil,
                                                         applicationId: nil)

        let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                           authorizationProxy: authProxy,
                                                           upstreamSessionProvider: nil)

        // To take the advantage of using IAB Open Measurement,
        // the SSAI Plugin for iOS provides a new signature:
        // BCOVPlayerSDKManager.sharedManager().createSSAISessionProvider(withUpstreamSessionProvider:, omidPartner:)
        //
        // let ssaiSessionProvider = sdkManager.createSSAISessionProvider(withUpstreamSessionProvider: fps,
        //                                                                omidPartner: "yourOmidPartner")
        //
        // The `omidPartner` string identifies the integration.
        // The value can not be empty or nil, if partner is not available, use "unknown".
        // The IAB Tech Lab will assign a unique partner name to you at the time of integration,
        // so this is the value you should use here.

        let ssaiSessionProvider = sdkManager.createSSAISessionProvider(withUpstreamSessionProvider: fps)

        guard let playerView else {
            return nil
        }

        let playbackController = sdkManager.createPlaybackController(withSessionProvider: ssaiSessionProvider,
                                                                     viewStrategy: nil)

        // Create a companion slot.
        let companionSlot = BCOVSSAICompanionSlot(view: companionSlotContainerView,
                                                  width: 300,
                                                  height: 250)

        // In order to display an ad progress banner on the top of the view,
        // we create this display container. This object is also responsible
        // for populating the companion slots.
        let adComponentDisplayContainer = BCOVSSAIAdComponentDisplayContainer(companionSlots: [companionSlot])

        // In order for the ad display container to receive ad information,
        // we add it as a session consumer.
        playbackController.add(adComponentDisplayContainer)

        playbackController.delegate = self
        playbackController.isAutoAdvance = true
        playbackController.isAutoPlay = true

        playerView.playbackController = playbackController

        return playbackController
    }()

    // When this value is set to YES the playback service
    // will be bypassed and a hard-coded VMAP URL will be used
    // to create a BCOVVideo instead
    fileprivate let useVMAPURL = false
    
    // When this value is set to YES the PAL SDK
    // will be used in conjuction with the Brightcove SSAI plugin
    fileprivate let usePAL = false
    
    // If using PAL SDK uncomment these properties
//    fileprivate var didSendPlaybackStart = false
//    fileprivate var nonceLoader: NonceLoader?
//    fileprivate var nonceManager: NonceManager?
//    fileprivate var PALNonce: String?

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
                                               selector: #selector(applicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc
    fileprivate func applicationDidBecomeActive(_ notification: NSNotification) {
        if usePAL {
            // If using PAL SDK uncomment this line
//            setUpPAL()
        } else {
            requestTrackingAuthorization()
        }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

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
                    videoSetUp()
                }

            }
        } else {
            if useVMAPURL {
                if let playbackController,
                   let url = URL(string: kVMAPURL) {
                    let video = BCOVVideo.video(withURL: url)
                    playbackController.setVideos([video])
                }
            } else {
                requestContentFromPlaybackService()
            }
        }
    }
    
    fileprivate func videoSetUp() {
        if useVMAPURL {
            if let playbackController,
               let url = URL(string: kVMAPURL) {
                let video = BCOVVideo.video(withURL: url)

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

                playbackController.setVideos([video])
            }
        } else {
            requestContentFromPlaybackService()
        }
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
        let queryParameters = [BCOVPlaybackService.ParamaterKeyAdConfigId: kAdConfigId]

        playbackService.findVideo(withConfiguration: configuration,
                                  queryParameters: queryParameters) {
            [playbackController] (video: BCOVVideo?,
                                  jsonResponse: Any?,
                                  error: Error?) in
            guard let playbackController,
                  var video else {
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
            // If using PAL SDK uncomment this block
//            if self.usePAL {
//                if let jsonResponse = jsonResponse {
//                    let updatedJSON = self.appendPALNonce(forJSON: jsonResponse)
//                    video = BCOVPlaybackService.video(fromJSONDictionary: updatedJSON)
//                }
//            }
            playbackController.setVideos([video])
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
        
        // If using PAL SDK uncomment this block
//        if usePAL {
//            if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventPlay && !didSendPlaybackStart {
//                didSendPlaybackStart = true
//                nonceManager?.sendPlaybackStart()
//            }
//
//            if lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd {
//                nonceManager?.sendPlaybackEnd()
//            }
//        }
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
    
    func willOpenExternalBrowser(with ad: BCOVAd!) {
        if usePAL {
            // If using PAL SDK uncomment this line
//            nonceManager?.sendAdClick()
        }
    }
}

// MARK: - PAL Integration
// If using PAL SDK uncomment these methods

//extension ViewController {
//    
//    func setUpPAL() {
//        // The default value for 'allowStorage' and 'directedForChildOrUnknownAge' is
//        // 'NO', but should be updated once the appropriate consent has been gathered.
//        // Publishers should either integrate with a CMP or use a different method to
//        // handle storage consent.
//        let settings = Settings()
//        settings.allowStorage = true
//        settings.directedForChildOrUnknownAge = false
//
//        nonceLoader = NonceLoader(settings: settings)
//        nonceLoader?.delegate = self
//
//        requestNonceManager()
//    }
//
//    func requestNonceManager() {
//        // See https://developers.google.com/ad-manager/pal/ios/reference/Classes/PALNonceRequest
//        // for all possible configurations.
//        let request = NonceRequest()
//        request.continuousPlayback = Flag.off
//        request.playerType = "BasicSSAIPlayer"
//        request.playerVersion = "1.0.0"
//        request.sessionID = NSUUID().uuidString
//        request.willAdAutoPlay = Flag.on
//        request.willAdPlayMuted = Flag.off
//
//        nonceLoader?.loadNonceManager(with: request)
//    }
//
//    func appendPALNonce(forJSON json: [AnyHashable: Any]) -> [AnyHashable: Any] {
//        guard let sources = json["sources"] as? [[AnyHashable:Any]] else {
//            return json
//        }
//        var updatedJson = json
//        var updatedSources = [[AnyHashable:Any]]()
//        for source in sources {
//            guard var vmapURL = source["vmap"] as? String, let PALNonce = PALNonce else {
//                continue
//            }
//            vmapURL = "\(vmapURL)&givn=\(PALNonce)"
//            var updatedSource = source
//            updatedSource["vmap"] = vmapURL
//            updatedSources.append(updatedSource)
//        }
//        updatedJson["sources"] = updatedSources
//        return updatedJson
//    }
//
//}

// MARK: - PAL Integration
// If using PAL SDK uncomment these methods

//extension ViewController: NonceLoaderDelegate {
//    
//    func nonceLoader(_ nonceLoader: NonceLoader, with request: NonceRequest, didLoad nonceManager: NonceManager) {
//        print("Programmatic access nonce: \(nonceManager.nonce)")
//        // Capture the created nonce manager and attach its gesture recognizer to the video view.
//        self.nonceManager = nonceManager
//
//        PALNonce = nonceManager.nonce
//
//        videoSetUp()
//    }
//
//    func nonceLoader(_ nonceLoader: NonceLoader, with request: NonceRequest, didFailWith error: any Error) {
//        print("Error generating programmatic access nonce: \(error)")
//    }
//}
