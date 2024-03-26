//
//  SettingsViewController.swift
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit

import BrightcovePlayerSDK


fileprivate struct DefaultSettings {
    static let Bitrate: Int64 = 1000000
    static let RentalDuration: Int64 = 3600
    static let PlayDuration: Int64 = 600
}


final class SettingsViewController: UIViewController {

    @IBOutlet fileprivate weak var allowCellularDownloadSwitch: UISwitch! {
        didSet {
#if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
            allowCellularDownloadSwitch.isEnabled = false
#else
            allowCellularDownloadSwitch.addTarget(self,
                                                  action: #selector(doAllowDownloadsOverCellular(_:)),
                                                  for: .valueChanged)
#endif
        }
    }

    @IBOutlet fileprivate weak var bitrateTextField: UITextField! {
        didSet {
            bitrateTextField.text = "\(DefaultSettings.Bitrate)"
            bitrateTextField.inputAccessoryView = keyboardDoneButtonView
        }
    }

    @IBOutlet fileprivate weak var licenseTypeSegmentedControl: UISegmentedControl! {
        didSet {
            licenseTypeSegmentedControl.addTarget(self,
                                                  action: #selector(doLicenseTypeChange),
                                                  for: .valueChanged)
        }
    }

    @IBOutlet fileprivate weak var rentalDurationTextField: UITextField! {
        didSet {
            rentalDurationTextField.text = "\(DefaultSettings.RentalDuration)"
            rentalDurationTextField.inputAccessoryView = keyboardDoneButtonView
        }
    }

    @IBOutlet fileprivate weak var playDurationTextField: UITextField! {
        didSet {
            playDurationTextField.text = "\(DefaultSettings.PlayDuration)"
            playDurationTextField.inputAccessoryView = keyboardDoneButtonView
        }
    }

    @IBOutlet fileprivate weak var sdkVersionLabel: UILabel! {
        didSet {
            if let sdkVersion = BCOVPlayerSDKManager.version() {
                sdkVersionLabel.text = "BrightcovePlayerSDK v\(sdkVersion)"
            }
        }
    }

    // Add a "Done" button to the numeric keyboard
    fileprivate lazy var keyboardDoneButtonView: UIToolbar = {
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(doneClicked))

        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.setItems([doneButton], animated: false)
        keyboardDoneButtonView.sizeToFit()

        return keyboardDoneButtonView
    }()

    var allowDownloadsOverCellular: Bool {
        return allowCellularDownloadSwitch.isOn
    }

    var purchaseLicenseType: Bool {
        return licenseTypeSegmentedControl?.selectedSegmentIndex == 1
    }

    var bitrate: Int64 {
        guard let textValue = bitrateTextField?.text,
              let bitrate = Int64(textValue) else {
            return DefaultSettings.Bitrate
        }

        return bitrate
    }

    var rentalDuration: Int64 {
        guard let textValue = rentalDurationTextField?.text,
              let rentalDuration = Int64(textValue) else {
            return DefaultSettings.RentalDuration
        }

        return rentalDuration
    }

    var playDuration: Int64 {
        guard let textValue = playDurationTextField?.text,
              let playDuration = Int64(textValue) else {
            return DefaultSettings.PlayDuration
        }

        return playDuration
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        doLicenseTypeChange()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

#if !targetEnvironment(simulator) && !targetEnvironment(macCatalyst)
    @objc
    fileprivate func doAllowDownloadsOverCellular(_ sender: UISwitch) {
        let isOn = NSNumber(booleanLiteral: sender.isOn)

        let options = [
            kBCOVOfflineVideoManagerAllowsCellularDownloadKey: isOn,
            kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: isOn,
            kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: isOn
        ]

        // Re-initialize with same delegate, but new options.
        BCOVOfflineVideoManager.initializeOfflineVideoManager(with: DownloadManager.shared,
                                                              options: options)
    }
#endif
    
    @objc
    fileprivate func doLicenseTypeChange() {
        rentalDurationTextField.isEnabled = !purchaseLicenseType
        playDurationTextField.isEnabled = purchaseLicenseType
    }

    @objc
    fileprivate func doneClicked() {
        view.endEditing(true)
    }
}
