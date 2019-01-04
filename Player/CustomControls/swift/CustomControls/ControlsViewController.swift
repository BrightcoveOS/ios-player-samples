//
//  ControlsViewController.swift
//  CustomControls
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

fileprivate struct ControlConstants {
    static let VisibleDuration: TimeInterval = 5.0
    static let AnimateInDuration: TimeInterval = 0.1
    static let AnimateOutDuraton: TimeInterval = 0.2
}

class ControlsViewController: UIViewController {

    weak var delegate: ControlsViewControllerFullScreenDelegate?
    private weak var currentPlayer: AVPlayer?
    
    @IBOutlet weak private var controlsContainer: UIView!
    @IBOutlet weak private var playPauseButton: UIButton!
    @IBOutlet weak private var playheadLabel: UILabel!
    @IBOutlet weak private var playheadSlider: UISlider!
    @IBOutlet weak private var durationLabel: UILabel!
    @IBOutlet weak private var fullscreenButton: UIView!
    @IBOutlet weak private var externalScreenButton: MPVolumeView!
    
    private var controlTimer: Timer?
    private var playingOnSeek: Bool = false
    
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.paddingCharacter = "0"
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Used for hiding and showing the controls.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        
        externalScreenButton.showsRouteButton = true
        externalScreenButton.showsVolumeSlider = false
    }
    
    // MARK: - Misc
    
    @objc private func tapDetected() {
        if playPauseButton.isSelected {
            if controlsContainer.alpha == 0.0 {
                fadeControlsIn()
            } else if (controlsContainer.alpha == 1.0) {
                fadeControlsOut()
            }
        }
    }
    
    private func fadeControlsIn() {
        UIView.animate(withDuration: ControlConstants.AnimateInDuration, animations: {
            self.showControls()
        }) { [weak self](finished: Bool) in
            if finished {
                self?.reestablishTimer()
            }
        }
    }
    
    @objc private func fadeControlsOut() {
        UIView.animate(withDuration: ControlConstants.AnimateOutDuraton) {
            self.hideControls()
        }

    }
    
    private func reestablishTimer() {
        controlTimer?.invalidate()
        controlTimer = Timer.scheduledTimer(timeInterval: ControlConstants.VisibleDuration, target: self, selector: #selector(fadeControlsOut), userInfo: nil, repeats: false)
    }
    
    private func hideControls() {
        controlsContainer.alpha = 0.0
    }
    
    private func showControls() {
        controlsContainer.alpha = 1.0
    }
    
    private func invalidateTimerAndShowControls() {
        controlTimer?.invalidate()
        showControls()
    }
    
    private func formatTime(timeInterval: TimeInterval) -> String? {
        if (timeInterval.isNaN || !timeInterval.isFinite || timeInterval == 0) {
            return "00:00"
        }
        
        let hours  = floor(timeInterval / 60.0 / 60.0)
        let minutes = (timeInterval / 60).truncatingRemainder(dividingBy: 60)
        let seconds = timeInterval.truncatingRemainder(dividingBy: 60)
        
        guard let formattedMinutes = numberFormatter.string(from: NSNumber(value: minutes)), let formattedSeconds = numberFormatter.string(from: NSNumber(value: seconds)) else {
            return nil
        }
        
        return hours > 0 ? "\(hours):\(formattedMinutes):\(formattedSeconds)" : "\(formattedMinutes):\(formattedSeconds)"
    }
    
    // MARK: - IBActions

    @IBAction func handleFullScreenButtonPressed(_ button: UIButton) {
        if button.isSelected {
            button.isSelected = false
            delegate?.handleExitFullScreenButtonPressed()
        } else {
            button.isSelected = true
            delegate?.handleEnterFullScreenButtonPressed()
        }
    }
    
    @IBAction func handlePlayheadSliderTouchEnd(_ slider: UISlider) {
        if let currentTime = currentPlayer?.currentItem {
            let newCurrentTime = Float64(slider.value) * CMTimeGetSeconds(currentTime.duration)
            let seekToTime = CMTimeMakeWithSeconds(newCurrentTime, preferredTimescale: 600)
            
            currentPlayer?.seek(to: seekToTime, completionHandler: { [weak self] (finished: Bool) in
                self?.playingOnSeek = false
                self?.currentPlayer?.play()
            })
        }
    }
    
    @IBAction func handlePlayheadSliderTouchBegin(_ slider: UISlider) {
        playingOnSeek = playPauseButton.isSelected
        currentPlayer?.pause()
    }
    
    @IBAction func handlePlayheadSliderValueChanged(_ slider: UISlider) {
        if let currentTime = currentPlayer?.currentItem {
            let currentTime = Float64(slider.value) * CMTimeGetSeconds(currentTime.duration)
            playheadLabel.text = formatTime(timeInterval: currentTime)
        }
        
    }
    
    @IBAction func handlePlayPauseButtonPressed(_ button: UIButton) {
        if button.isSelected {
            currentPlayer?.pause()
        } else {
            currentPlayer?.play()
        }
    }

}

// MARK: - UIGestureRecognizerDelegate

extension ControlsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // This makes sure that we don't try and hide the controls if someone is pressing any of the buttons
        // or slider.
        
        guard let view = touch.view else {
            return true
        }
        
        if ( view.isKind(of: UIButton.classForCoder()) || view.isKind(of: UISlider.classForCoder()) ) {
            return false
        }
        
        return true
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
    
    func playbackSession(_ session: BCOVPlaybackSession!, didChangeDuration duration: TimeInterval) {
        durationLabel.text = formatTime(timeInterval: duration)
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        playheadLabel.text = formatTime(timeInterval: progress)
        
        guard let currentItem = session.player.currentItem else {
            return
        }
        
        let duration = CMTimeGetSeconds(currentItem.duration)
        let percent = Float(progress / duration)
        playheadSlider.value = percent.isNaN ? 0.0 : percent
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        switch lifecycleEvent.eventType {
        case kBCOVPlaybackSessionLifecycleEventPlay:
            playPauseButton?.isSelected = true
            reestablishTimer()
        case kBCOVPlaybackSessionLifecycleEventPause:
            playPauseButton.isSelected = false
            invalidateTimerAndShowControls()
        default:
            break
        }
        
    }
    
}

// MARK: - ControlsViewControllerFullScreenDelegate

protocol ControlsViewControllerFullScreenDelegate: class {
    func handleEnterFullScreenButtonPressed()
    func handleExitFullScreenButtonPressed()
}
