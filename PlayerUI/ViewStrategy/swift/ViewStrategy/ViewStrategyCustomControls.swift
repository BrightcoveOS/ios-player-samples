//
//  ViewStrategyCustomControls.swift
//  ViewStrategy
//
//  Created by Carlos Ceja.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


class ViewStrategyCustomControls: UIView {
    
    private weak var playbackController: BCOVPlaybackController?
    
    var currentTimeLabel: UILabel?
    var durationTimeLabel: UILabel?
    var playImageView: UIImageView?
    var pauseImageView: UIImageView?
    var playPauseButton: UIButton?
    var progressView: UIProgressView?
    
    var isPlaying: Bool?


    init(playbackController: BCOVPlaybackController?) {
        super.init(frame: CGRect.zero)
        
        self.playbackController = playbackController
        
        self.isPlaying = self.playbackController?.isAutoPlay
        
        setup()
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() -> Void {
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        do {
            self.currentTimeLabel = UILabel()
            self.currentTimeLabel?.text = "00:00"
            self.currentTimeLabel?.textColor = UIColor.white
        }
        
        do {
            self.durationTimeLabel = UILabel()
            self.durationTimeLabel?.text = "00:00"
            self.durationTimeLabel?.textColor = UIColor.white
        }
        
        do {
            self.progressView = UIProgressView()
            self.progressView?.progress = 0.0
            self.progressView?.backgroundColor = UIColor.white
        }
        
        do {
            let originalImage = UIImage(named: "PlayButton")
            let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
            
            self.playImageView = UIImageView(image: tintedImage)
            self.playImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.playImageView?.contentMode = .scaleAspectFit
            self.playImageView?.tintColor = UIColor.white
            self.playImageView?.isUserInteractionEnabled = false
            self.playImageView?.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
            self.playImageView?.bounds = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0).insetBy(dx: 7.0, dy: 7.0)
        }
        
        do {
            let originalImage = UIImage(named: "PauseButton")
            let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
            
            self.pauseImageView = UIImageView(image: tintedImage)
            self.pauseImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.pauseImageView?.contentMode = .scaleAspectFit
            self.pauseImageView?.tintColor = UIColor.white
            self.pauseImageView?.isUserInteractionEnabled = false
            self.pauseImageView?.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
            self.pauseImageView?.bounds = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0).insetBy(dx: 7.0, dy: 7.0)
        }
        
        do {
            self.playPauseButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0))
            self.playPauseButton?.addTarget(self, action: #selector(playPauseButtonPressed(_:)), for: .touchUpInside)
            
            self.playPauseButton?.addSubview(self.playImageView!)
            self.playPauseButton?.addSubview(self.pauseImageView!)
        }

    }
    
    func setupConstraints() -> Void {
        
        do {
            let currentTimeLabel = self.currentTimeLabel
            currentTimeLabel?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(currentTimeLabel!)

            let durationTimeLabel = self.durationTimeLabel
            durationTimeLabel?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(durationTimeLabel!)

            let playPauseButton = self.playPauseButton
            playPauseButton?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(playPauseButton!)
            
            let option: NSLayoutConstraint.FormatOptions = .directionLeadingToTrailing
            let views = [
                "currentTimeLabel" : currentTimeLabel,
                "durationTimeLabel" : durationTimeLabel,
                "playPauseButton" : playPauseButton
            ]

            let hcCurrentTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[currentTimeLabel(>=30,<=50)]", options: option, metrics: nil, views: views as [String : Any])

            let vcCurrentTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "V:[currentTimeLabel(30)]-10-|", options: option, metrics: nil, views: views as [String : Any])
            
            let hcDurationTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "H:[durationTimeLabel(>=30,<=50)]-20-|", options: option, metrics: nil, views: views as [String : Any])

            let vcDurationTimeLabel = NSLayoutConstraint.constraints(withVisualFormat: "V:[durationTimeLabel(30)]-10-|", options: option, metrics: nil, views: views as [String : Any])

            let hcPlayPauseButton = NSLayoutConstraint.constraints(withVisualFormat: "V:[superview]-(<=1)-[playPauseButton]", options: .alignAllCenterX, metrics: nil, views: [
                "superview": self,
                "playPauseButton": playPauseButton as Any
            ])

            let vcPlayPauseButton = NSLayoutConstraint.constraints(withVisualFormat: "V:[playPauseButton(30)]-10-|", options: option, metrics: nil, views: views as [String : Any])

            addConstraints(hcCurrentTimeLabel)
            addConstraints(vcCurrentTimeLabel)
            addConstraints(hcDurationTimeLabel)
            addConstraints(vcDurationTimeLabel)
            addConstraints(hcPlayPauseButton)
            addConstraints(vcPlayPauseButton)
        }
        
        do {
            let view = self.progressView
            view?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view!)

            let option: NSLayoutConstraint.FormatOptions = .directionLeadingToTrailing
            let views = [
                "view" : view
            ]

            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: option, metrics: nil, views: views as [String : Any])

            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[view(5)]|", options: option, metrics: nil, views: views as [String : Any])

            addConstraints(horizontalConstraints)
            addConstraints(verticalConstraints)
        }

    }
    
    @objc
    func playPauseButtonPressed(_ sender: Any?) {
        
        self.isPlaying = !self.isPlaying!

        if self.isPlaying! {
            self.playPauseButton?.subviews[0].isHidden = true
            self.playPauseButton?.subviews[1].isHidden = false
            self.playbackController?.play()
        } else {
            self.playPauseButton?.subviews[0].isHidden = false
            self.playPauseButton?.subviews[1].isHidden = true
            self.playbackController?.pause()
        }

    }
    
    class func timeFormatter(_ seconds: TimeInterval) -> String? {
        
        let dcFormatter = DateComponentsFormatter()
        dcFormatter.zeroFormattingBehavior = .pad
        dcFormatter.allowedUnits = [.minute, .second]
        let formatted = dcFormatter.string(from: seconds)
        
        return formatted

    }
    
}

extension ViewStrategyCustomControls: BCOVPlaybackSessionConsumer {
    
    func didAdvance(to session: BCOVPlaybackSession?) {
        if self.isPlaying! {
            self.playPauseButton?.subviews[0].isHidden = true
        }
    }
    
    func playbackSession(_ session: BCOVPlaybackSession?, didProgressTo progress: TimeInterval) {
        var duration: TimeInterval? = nil
        if let duration1 = session?.player.currentItem?.duration {
            duration = TimeInterval(CMTimeGetSeconds(duration1))
        }
        let percent = Float(progress / (duration ?? 0.0))

        self.progressView?.progress = !percent.isNaN ? percent : 0.0

        if progress >= 0.0 {
            self.currentTimeLabel?.text = ViewStrategyCustomControls.timeFormatter(progress)
        }
    }

    func playbackSession(_ session: BCOVPlaybackSession?, didChangeDuration duration: TimeInterval) {
        self.durationTimeLabel?.text = ViewStrategyCustomControls.timeFormatter(duration)
    }

}
