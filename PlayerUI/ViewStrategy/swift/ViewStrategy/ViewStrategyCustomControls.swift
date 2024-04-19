//
//  ViewStrategyCustomControls.swift
//  ViewStrategy
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


final class ViewStrategyCustomControls: UIView {

    fileprivate weak var playbackController: BCOVPlaybackController?
    fileprivate weak var player: AVPlayer?

    fileprivate lazy var currentTimeLabel: UILabel = {
        let currentTimeLabel = UILabel()
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 20)
        return currentTimeLabel
    }()

    fileprivate lazy var durationTimeLabel: UILabel = {
        let durationTimeLabel = UILabel()
        durationTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationTimeLabel.text = "00:00"
        durationTimeLabel.textColor = .white
        durationTimeLabel.font = .systemFont(ofSize: 20)
        return durationTimeLabel
    }()

    fileprivate lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.frame.size = bounds.size
        progressView.frame.origin = CGPoint(x: 0, y: bounds.height)
        progressView.progress = 0.0
        progressView.backgroundColor = .white
        return progressView
    }()

    fileprivate lazy var playImage: UIImage? = UIImage(named: "play.fill")

    fileprivate lazy var pauseImage: UIImage? = UIImage(named: "pause.fill")

    fileprivate lazy var playPauseButton: UIButton = {
        let playPauseButton = UIButton(frame: CGRect(x: 0, y: 0,
                                                     width: 50, height: 50))
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.tintColor = .white
        playPauseButton.setImage(playImage, for: .normal)
        playPauseButton.addTarget(self,
                                  action: #selector(playPauseButtonPressed),
                                  for: .touchUpInside)
        return playPauseButton
    }()

    init(with playbackController: BCOVPlaybackController?) {
        super.init(frame: .zero)

        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.playbackController = playbackController

        addSubview(currentTimeLabel)
        addSubview(durationTimeLabel)
        addSubview(playPauseButton)
        addSubview(progressView)

        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var constraints: [NSLayoutConstraint] {
        let option: NSLayoutConstraint.FormatOptions = .directionLeadingToTrailing
        let views = [
            "superview": self,
            "currentTimeLabel": currentTimeLabel,
            "durationTimeLabel": durationTimeLabel,
            "playPauseButton": playPauseButton,
            "progressView": progressView
        ]

        let hcCurrentTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[currentTimeLabel(>=30,<=100)]",
                                                                options: option,
                                                                metrics: nil,
                                                                views: views)

        let vcCurrentTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "V:[currentTimeLabel(50)]-10-|",
                                                                options: option,
                                                                metrics: nil,
                                                                views: views)

        let hcDurationTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "H:[durationTimeLabel(>=30,<=100)]-20-|",
                                                                 options: option,
                                                                 metrics: nil,
                                                                 views: views)

        let vcDurationTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "V:[durationTimeLabel(50)]-10-|",
                                                                 options: option,
                                                                 metrics: nil,
                                                                 views: views)

        let hcPlayPauseButton = NSLayoutConstraint.constraints(withVisualFormat: "V:[superview]-(<=1)-[playPauseButton]",
                                                               options: .alignAllCenterX,
                                                               metrics: nil,
                                                               views: views)

        let vcPlayPauseButton = NSLayoutConstraint.constraints(withVisualFormat: "V:[playPauseButton(50)]-10-|",
                                                               options: option,
                                                               metrics: nil,
                                                               views: views)

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[progressView]|",
                                                                   options: option,
                                                                   metrics: nil,
                                                                   views: views)

        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[progressView(5)]|",
                                                                 options: option,
                                                                 metrics: nil,
                                                                 views: views)

        return [
            hcCurrentTimeLabel,
            vcCurrentTimeLabel,
            hcDurationTimeLabel,
            vcDurationTimeLabel,
            hcPlayPauseButton,
            vcPlayPauseButton,
            horizontalConstraints,
            verticalConstraints
        ].flatMap { $0 }
    }

    @objc
    func playPauseButtonPressed() {
        guard let playbackController,
              let player else { return }

        if player.timeControlStatus == .playing {
            playPauseButton.setImage(playImage, for: .normal)
            playbackController.pause()
        } else {
            playPauseButton.setImage(pauseImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            playbackController.play()
        }
    }

    class func timeFormatter(_ seconds: TimeInterval) -> String? {
        let dcFormatter = DateComponentsFormatter()
        dcFormatter.zeroFormattingBehavior = .pad
        dcFormatter.allowedUnits = seconds < 3600 ? [.minute, .second] : [.hour, .minute, .second]
        let formatted = dcFormatter.string(from: seconds)

        return formatted
    }
}


// MARK: - BCOVPlaybackSessionConsumer

extension ViewStrategyCustomControls: BCOVPlaybackSessionConsumer {

    func didAdvance(to session: BCOVPlaybackSession) {
        player = session.player

        if let playbackController,
           playbackController.isAutoPlay {
            playPauseButton.setImage(pauseImage, for: .normal)
        }
    }

    func playbackSession(_ session: BCOVPlaybackSession!,
                         didProgressTo progress: TimeInterval) {
        guard let duration = session.player.currentItem?.duration,
              duration.isValid,
              progress.isFinite else {
            return
        }

        progressView.progress = Float(progress / CMTimeGetSeconds(duration))
        currentTimeLabel.text = ViewStrategyCustomControls.timeFormatter(progress)
    }

    func playbackSession(_ session: BCOVPlaybackSession,
                         didChangeDuration duration: TimeInterval) {
        durationTimeLabel.text = ViewStrategyCustomControls.timeFormatter(duration)
    }
}
