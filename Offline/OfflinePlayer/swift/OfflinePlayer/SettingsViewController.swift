//
//  SettingsViewController.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

struct DefaultSettings {
    static let Bitrate: Int64 = 1000000
    static let RentalDuration: Int64 = 3600
}

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 45
        }
    }
    
    weak var bitrateTextField: UITextField? {
        didSet {
            bitrateTextField?.text = "\(DefaultSettings.Bitrate)"
        }
    }
    weak var rentalDurationTextField: UITextField? {
        didSet {
            rentalDurationTextField?.text = "\(DefaultSettings.RentalDuration)"
            rentalDurationTextField?.isEnabled = !isPurchaseLicenseType()
            rentalDurationTextField?.alpha = !isPurchaseLicenseType() ? 1.0 : 0.5
        }
    }
    weak var licenseTypeSegmentedControl: UISegmentedControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func bitrate() -> Int64 {
        guard let textValue = bitrateTextField?.text, let bitrate = Int64(textValue) else {
            return DefaultSettings.Bitrate
        }
        
        return bitrate
    }
    
    func rentalDuration() -> Int64 {
        guard let textValue = rentalDurationTextField?.text, let durationSeconds = Int64(textValue) else {
            return DefaultSettings.RentalDuration
        }
        
        return durationSeconds
    }
    
    func isPurchaseLicenseType() -> Bool {
        return licenseTypeSegmentedControl?.selectedSegmentIndex == 1
    }
    
    // MARK: - Notification Methods
    
    @objc private func keyboardWillShow() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        doneButton.tintColor = UIColor(red: 63.0/255.0, green: 35.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc private func keyboardWillHide() {
        navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: - UI Actions
    
    @objc private func doneButtonPressed(_ button: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    @objc private func allowDownloadsOverCellularSwitchValueChanged(_ theSwitch: UISwitch) {
        
        guard let downloadManager = tabBarController?.streamingViewController()?.downloadManager else {
            return
        }
        
        let isOn = NSNumber(booleanLiteral: theSwitch.isOn)
        
        let optionsDictionary = [
            kBCOVOfflineVideoManagerAllowsCellularDownloadKey: isOn,
            kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: isOn,
            kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: isOn
        ]
        
        // Re-initialize with same delegate, but new options.
        BCOVOfflineVideoManager.initializeOfflineVideoManager(with: downloadManager, options: optionsDictionary)
    }
    
    @objc private func licenseTypeChanged(_ segmentedControl: UISegmentedControl) {
        tableView.reloadData()
    }

}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            cell.theSwitch.addTarget(self, action: #selector(allowDownloadsOverCellularSwitchValueChanged(_:)), for: .valueChanged)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            bitrateTextField = cell.textField
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlCell", for: indexPath) as! SegmentedControlTableViewCell
            licenseTypeSegmentedControl = cell.segmentedControl
            cell.segmentedControl.addTarget(self, action: #selector(licenseTypeChanged(_:)), for: .valueChanged)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            rentalDurationTextField = cell.textField
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Allow Cellular Downloads"
        case 1:
            return "Bitrate to Download"
        case 2:
            return "License Type"
        case 3:
            return "Rental Duration"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 3 ? "Values specified in seconds" : nil
    }
    
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 3 ? 35 : 15
    }
    
}
