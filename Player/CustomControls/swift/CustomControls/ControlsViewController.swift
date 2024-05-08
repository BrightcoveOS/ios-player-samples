//
//  ControlsViewController.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


fileprivate struct ControlConstants {
    static let VisibleDuration: TimeInterval = 5.0
    static let AnimateInDuration: TimeInterval = 0.1
    static let AnimateOutDuraton: TimeInterval = 0.2
}


final class ControlsViewController: UIViewController {

    @IBOutlet fileprivate weak var controlsContainer: UIView!
    @IBOutlet fileprivate weak var playPauseButton: UIButton!
    @IBOutlet fileprivate weak var playheadLabel: UILabel!
    @IBOutlet fileprivate weak var playheadSlider: UISlider!
    @IBOutlet fileprivate weak var durationLabel: UILabel!
    @IBOutlet fileprivate weak var fullscreenButton: UIButton!
    @IBOutlet fileprivate weak var externalScreenButton: MPVolumeView!
    @IBOutlet fileprivate weak var closedCaptionButton: UIButton!

    weak var delegate: ControlsViewControllerFullScreenDelegate?
    weak var currentPlayer: AVPlayer?
    weak var playbackController: BCOVPlaybackController?

    var closedCaptionEnabled: Bool = false {
        didSet {
            closedCaptionButton.isEnabled = closedCaptionEnabled
        }
    }

    fileprivate var controlTimer: Timer?
    fileprivate var playingOnSeek: Bool = false

    fileprivate lazy var ccMenuController: ClosedCaptionMenuController = {
        let ccMenuController = ClosedCaptionMenuController(style: .grouped)
        ccMenuController.controlsView = self
        return ccMenuController
    }()

    fileprivate lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.paddingCharacter = "0"
        formatter.minimumIntegerDigits = 2
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Used for hiding and showing the controls.
        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(tapDetected))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)

        externalScreenButton.showsRouteButton = true
        externalScreenButton.showsVolumeSlider = false

        closedCaptionButton.isEnabled = false
    }

    @objc
    fileprivate func tapDetected() {
        if playPauseButton.isSelected {
            if controlsContainer.alpha == 0.0 {
                fadeControlsIn()
            } else if (controlsContainer.alpha == 1.0) {
                fadeControlsOut()
            }
        }
    }

    fileprivate func fadeControlsIn() {
        UIView.animate(withDuration: ControlConstants.AnimateInDuration) { [self] in
            showControls()
        } completion:{ [self] (finished: Bool) in
            if finished {
                reestablishTimer()
            }
        }
    }

    @objc
    fileprivate func fadeControlsOut() {
        UIView.animate(withDuration: ControlConstants.AnimateOutDuraton) { [self] in
            hideControls()
        }
    }

    fileprivate func reestablishTimer() {
        controlTimer?.invalidate()
        controlTimer = Timer.scheduledTimer(timeInterval: ControlConstants.VisibleDuration,
                                            target: self,
                                            selector: #selector(fadeControlsOut),
                                            userInfo: nil,
                                            repeats: false)
    }

    fileprivate func hideControls() {
        controlsContainer.alpha = 0.0
    }

    fileprivate func showControls() {
        controlsContainer.alpha = 1.0
    }

    fileprivate func invalidateTimerAndShowControls() {
        controlTimer?.invalidate()
        showControls()
    }

    fileprivate func formatTime(timeInterval: TimeInterval) -> String? {
        if timeInterval.isNaN ||
            !timeInterval.isFinite ||
            timeInterval == 0 {
            return "00:00"
        }

        let hours  = floor(timeInterval / 60.0 / 60.0)
        let minutes = (timeInterval / 60).truncatingRemainder(dividingBy: 60)
        let seconds = timeInterval.truncatingRemainder(dividingBy: 60)

        guard let formattedMinutes = numberFormatter.string(from: NSNumber(value: minutes)),
              let formattedSeconds = numberFormatter.string(from: NSNumber(value: seconds)) else {
            return nil
        }

        return (hours > 0 ?
                "\(hours):\(formattedMinutes):\(formattedSeconds)" :
                    "\(formattedMinutes):\(formattedSeconds)")
    }

    @IBAction
    fileprivate func handleFullScreenButtonPressed(_ button: UIButton) {
        if button.isSelected {
            button.isSelected = false
            delegate?.handleExitFullScreenButtonPressed()
        } else {
            button.isSelected = true
            delegate?.handleEnterFullScreenButtonPressed()
        }
    }

    @IBAction
    fileprivate func handlePlayheadSliderTouchEnd(_ slider: UISlider) {
        if let currentTime = currentPlayer?.currentItem {
            let newCurrentTime = Float64(slider.value) * CMTimeGetSeconds(currentTime.duration)
            let seekToTime = CMTimeMakeWithSeconds(newCurrentTime, preferredTimescale: 600)

            playbackController?.seek(to: seekToTime) { [self] (finished: Bool) in
                playingOnSeek = false
                playbackController?.play()
            }
        }
    }

    @IBAction
    fileprivate func handlePlayheadSliderTouchBegin(_ slider: UISlider) {
        playingOnSeek = playPauseButton.isSelected
        playbackController?.pause()
    }

    @IBAction
    fileprivate func handlePlayheadSliderValueChanged(_ slider: UISlider) {
        if let currentTime = currentPlayer?.currentItem {
            let currentTime = Float64(slider.value) * CMTimeGetSeconds(currentTime.duration)
            playheadLabel.text = formatTime(timeInterval: currentTime)
        }
    }

    @IBAction
    fileprivate func handlePlayPauseButtonPressed(_ button: UIButton) {
        if button.isSelected {
            playbackController?.pause()
        } else {
            playbackController?.play()
        }
    }

    @IBAction 
    fileprivate func handleClosedCaptionButtonPressed(_ button: UIButton) {
        let navController = UINavigationController(rootViewController: ccMenuController)
        present(navController, animated: true, completion: nil)
    }
}


// MARK: - BCOVPlaybackSessionConsumer

extension ControlsViewController: BCOVPlaybackSessionConsumer {

    func didAdvance(to session: BCOVPlaybackSession!) {
        currentPlayer = session.player

        // Reset State
        playingOnSeek = false
        playheadLabel.text = formatTime(timeInterval: 0)
        playheadSlider.value = 0.0

        invalidateTimerAndShowControls()
    }

    func playbackSession(_ session: BCOVPlaybackSession!,
                         didChangeDuration duration: TimeInterval) {
        durationLabel.text = formatTime(timeInterval: duration)
    }

    func playbackSession(_ session: BCOVPlaybackSession!,
                         didProgressTo progress: TimeInterval) {
        playheadLabel.text = formatTime(timeInterval: progress)

        guard let currentItem = session.player.currentItem else {
            return
        }

        let duration = CMTimeGetSeconds(currentItem.duration)
        let percent = Float(progress / duration)
        playheadSlider.value = percent.isNaN ? 0.0 : percent
    }

    func playbackSession(_ session: BCOVPlaybackSession!,
                         didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {

        switch lifecycleEvent.eventType {
            case kBCOVPlaybackSessionLifecycleEventPlay:
                playPauseButton?.isSelected = true
                reestablishTimer()
            case kBCOVPlaybackSessionLifecycleEventPause:
                playPauseButton.isSelected = false
                invalidateTimerAndShowControls()
            case kBCOVPlaybackSessionLifecycleEventReady:
                ccMenuController.currentSession = session
            default:
                break
        }
    }
}


// MARK: - UIGestureRecognizerDelegate

extension ControlsViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, 
                           shouldReceive touch: UITouch) -> Bool {
        // This makes sure that we don't try and hide the controls 
        // if someone is pressing any of the buttons or slider.

        guard let view = touch.view else { return true }

        if view.isKind(of: UIButton.classForCoder()) ||
            view.isKind(of: UISlider.classForCoder()) {
            return false
        }

        return true
    }
}


// MARK: - ControlsViewControllerFullScreenDelegate

protocol ControlsViewControllerFullScreenDelegate: AnyObject {
    func handleEnterFullScreenButtonPressed()
    func handleExitFullScreenButtonPressed()
}
