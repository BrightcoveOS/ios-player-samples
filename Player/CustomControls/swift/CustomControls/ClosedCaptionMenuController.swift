//
//  ClosedCaptionMenuController.swift
//  CustomControls
//
//  Created by Jeremy Blaker on 3/2/21.
//  Copyright © 2021 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

fileprivate struct ClosedCaptionMenuConfig {
    static let LegibleOptionsOffItemIndex = 0
    static let LegibleOptionsAutoItemIndex = 1
    static let LegibleOptionsOffsetFromOffItem = 2
    static let CellReuseId = "ClosedCaptionCell"
    static let ClosedCaptionMenuOffItemTitle = "Off"
    static let ClosedCaptionMenuAutoItemTitle = "Auto"
}

class ClosedCaptionMenuController: UITableViewController {
    
    weak var controlsView: ControlsViewController?
    weak var currentSession: BCOVPlaybackSession? {
        didSet {
            sessionWasSet()
        }
    }
    
    // a description of the sections of the media selection table view.
    private var mediaOptionsTableViewSectionList: [AVMediaCharacteristic]?

    // MARK: - View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentSession?.player.pause()
        
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Audio & Subtitles"
        
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: ClosedCaptionMenuConfig.CellReuseId)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonPressed(_:)))
    }
    
    // MARK: - UIActions
    
    @objc func doneButtonPressed(_ button: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: {
            self.currentSession?.player.play()
        })
    }
    
    
    // MARK: - Getters
    
    private func audibleMediaOptions() -> [AVMediaSelectionOption]? {
        
        guard let currentSession = currentSession else {
            return nil
        }
        
        // return the list of playable soundtracks.

        var playableSoundtracks: [AVMediaSelectionOption]?

        let soundtrackGroup = currentSession.audibleMediaSelectionGroup
        if let options = soundtrackGroup?.options {
            playableSoundtracks = AVMediaSelectionGroup.playableMediaSelectionOptions(from: options)
        }

        // set up the sort order. boil the language IDs down to their language codes (en, instead of en_US).
        let preferredLanguages = NSLocale.preferredLanguages
        var preferredLanguageCodes: [String] = []
        for aLanguage in preferredLanguages {
            guard let theLanguageCode = NSLocale.components(fromLocaleIdentifier: aLanguage)[NSLocale.Key.languageCode.rawValue] else {
                continue
            }
            if theLanguageCode != "" {
                preferredLanguageCodes.append(theLanguageCode)
            }
        }

        guard let _playableSoundtracks = playableSoundtracks as NSArray? else {
            return nil
        }
        
        // sort the options in order of preferred language.
        let sortedPlayableSoundtracks = _playableSoundtracks.sortedArray {
            (obj1, obj2) -> ComparisonResult in
            
            let option1 = obj1 as! AVMediaSelectionOption
            let option2 = obj2 as! AVMediaSelectionOption
            
            let option1LocaleIdentifier = option1.locale?.identifier ?? ""
            let option2LocaleIdentifier = option2.locale?.identifier ?? ""
            
            let localeKey = NSLocale.Key.languageCode.rawValue
            
            guard let codes1 = NSLocale.components(fromLocaleIdentifier: option1LocaleIdentifier)[localeKey],
                  let codes2 = NSLocale.components(fromLocaleIdentifier: option2LocaleIdentifier)[localeKey] else {
                return .orderedSame
            }
            
            var indexOfObj1 = preferredLanguageCodes.firstIndex(of: codes1) ?? NSNotFound
            if indexOfObj1 == NSNotFound {
                indexOfObj1 = Int.max
            }

            var indexOfObj2 = preferredLanguageCodes.firstIndex(of:  codes2) ?? NSNotFound
            if indexOfObj2 == NSNotFound {
                indexOfObj2 = Int.max
            }

            if indexOfObj2 > indexOfObj1 {
                return .orderedAscending
            }

            if indexOfObj2 < indexOfObj1 {
                return .orderedDescending
            }

            // neither item was in the list of user language prefs so apply a simple sort.
            return option1.displayName.caseInsensitiveCompare(option2.displayName)
            
        }
        
        return sortedPlayableSoundtracks as? [AVMediaSelectionOption]
    }
    
    private func legibleMediaOptions() -> [AVMediaSelectionOption]? {
        
        guard let currentSession = currentSession else {
            return nil
        }
        
        // return the list of playable, unforced subtitles & closed captions. refer
        // to "Advice about subtitles" in "AV Foundation Release Notes for iOS 5".
        // https://developer.apple.com/library/prerelease/mac/releasenotes/AudioVideo/RN-AVFoundation/index.html#//apple_ref/doc/uid/TP40010717-CH1-DontLinkElementID_3
        
        var unforcedLegibleOptions: [AVMediaSelectionOption]?

        guard let legibleGroup = currentSession.legibleMediaSelectionGroup else {
            return nil
        }

        // construct a list of subtitles and closed captions with valid locales.
        var validLegibleOptions = [AVMediaSelectionOption]()
        
        for option in legibleGroup.options {
            
            let isSubtitle = option.mediaType == .subtitle
            let isClosedCaption = option.mediaType == .closedCaption
            
            if isSubtitle || isClosedCaption {
                validLegibleOptions.append(option)
            }
            
        }
        
        // make sure they're playable and unforced.
        let playableLegibleOptions = AVMediaSelectionGroup.playableMediaSelectionOptions(from: validLegibleOptions)
        unforcedLegibleOptions = AVMediaSelectionGroup.mediaSelectionOptions(from: playableLegibleOptions, withoutMediaCharacteristics: [.containsOnlyForcedSubtitles])

        // define the sort order. boil the language IDs down to their language codes (en, instead of en_US).
        let preferredLanguages = NSLocale.preferredLanguages
        var preferredLanguageCodes: [String] = []
        for aLanguage in preferredLanguages {
            guard let theLanguageCode = NSLocale.components(fromLocaleIdentifier: aLanguage)[NSLocale.Key.languageCode.rawValue] else {
                continue
            }
            if theLanguageCode != "" {
                preferredLanguageCodes.append(theLanguageCode)
            }
        }
        
        guard let _unforcedLegibleOptions = unforcedLegibleOptions as NSArray? else {
            return nil
        }
        
        // sort the options in order of preferred language.
        let sortedLegibleOptions = _unforcedLegibleOptions.sortedArray {
            (obj1, obj2) -> ComparisonResult in
            
            let option1 = obj1 as! AVMediaSelectionOption
            let option2 = obj2 as! AVMediaSelectionOption
            
            let option1LocaleIdentifier = option1.locale?.identifier ?? ""
            let option2LocaleIdentifier = option2.locale?.identifier ?? ""

            let localeKey = NSLocale.Key.languageCode.rawValue
            
            guard let codes1 = NSLocale.components(fromLocaleIdentifier: option1LocaleIdentifier)[localeKey],
                  let codes2 = NSLocale.components(fromLocaleIdentifier: option2LocaleIdentifier)[localeKey] else {
                return .orderedSame
            }
            
            var indexOfObj1 = preferredLanguageCodes.firstIndex(of: codes1) ?? NSNotFound
            if indexOfObj1 == NSNotFound {
                indexOfObj1 = Int.max
            }

            var indexOfObj2 = preferredLanguageCodes.firstIndex(of:  codes2) ?? NSNotFound
            if indexOfObj2 == NSNotFound {
                indexOfObj2 = Int.max
            }

            if indexOfObj2 > indexOfObj1 {
                return .orderedAscending
            }

            if indexOfObj2 < indexOfObj1 {
                return .orderedDescending
            }

            // neither item was in the list of user language prefs so apply a simple sort.
            return option1.displayName.caseInsensitiveCompare(option2.displayName)
            
        }
        
        return sortedLegibleOptions as? [AVMediaSelectionOption]
        
    }

    // MARK: - Helpers
    
    private func tableViewSectionIsAudibleSection(_ section:  Int) -> Bool {
        guard let mediaOptionsTableViewSectionList = mediaOptionsTableViewSectionList else {
            return false
        }
        return mediaOptionsTableViewSectionList[section] == AVMediaCharacteristic.audible
    }
    
    private func tableViewSectionIsLegibleSection(_ section:  Int) -> Bool {
        guard let mediaOptionsTableViewSectionList = mediaOptionsTableViewSectionList else {
            return false
        }
        return mediaOptionsTableViewSectionList[section] == AVMediaCharacteristic.legible
    }
    
    private func sessionWasSet() {
        
        guard let audibleMediaOptions = audibleMediaOptions(), let legibileMediaOptions = legibleMediaOptions() else {
            controlsView?.closedCaptionEnabled = false
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            
            // new session. (re)build a list of the sections of the media option table view.
            var mediaOptionTypes = [AVMediaCharacteristic]()
            
            if audibleMediaOptions.count > 1 {
                mediaOptionTypes.append(AVMediaCharacteristic.audible)
            }
            
            if legibileMediaOptions.count > 0 {
                mediaOptionTypes.append(AVMediaCharacteristic.legible)
            }

            DispatchQueue.main.async {
                // Save an immutable copy.
                // Do this on main thread to prevent concurrency problems.
                self.mediaOptionsTableViewSectionList = mediaOptionTypes
                
                // Enable closed caption button if there are closed captions OR more than 1 soundtrack.
                // Do this on main thread because closedCaptionEnabled changes the UI.
                let closedCaptionEnabled = legibileMediaOptions.count > 0 || audibleMediaOptions.count > 1
                self.controlsView?.closedCaptionEnabled = closedCaptionEnabled
            }
            
        }
        
    }

}

// MARK: - UITableViewDataSource
extension ClosedCaptionMenuController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return mediaOptionsTableViewSectionList?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableViewSectionIsAudibleSection(section) {
            return audibleMediaOptions()?.count ?? 0
        } else if tableViewSectionIsLegibleSection(section) {
            guard let legibleMediaOptions = legibleMediaOptions() else {
                return 0
            }
            return legibleMediaOptions.count + ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableViewSectionIsAudibleSection(indexPath.section) {
            return audibleCell(forRowAtIndexPath: indexPath, tableView: tableView)
        } else if tableViewSectionIsLegibleSection(indexPath.section) {
            return legibleCell(forRowAtIndexPath: indexPath, tableView: tableView)
        }
        
        return UITableViewCell()
    }
    
    private func audibleCell(forRowAtIndexPath indexPath: IndexPath, tableView theTableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClosedCaptionMenuConfig.CellReuseId)!
        
        guard let audibleMediaOptions = audibleMediaOptions(), let currentSession = currentSession else {
            return cell
        }
        
        let option = audibleMediaOptions[indexPath.row]
        let displayName = currentSession.displayName(fromAudibleMediaSelectionOption: option) ?? ""
        cell.textLabel?.text = displayName
        
        // add a checkmark to the selected cell.
        let selectedOption = currentSession.selectedAudibleMediaOption
        
        // what's the index of the selectedOption?
        let selectedOptionDisplayName = currentSession.displayName(fromAudibleMediaSelectionOption: selectedOption)

        var selectionIndex = 0
        for option in audibleMediaOptions {
            let displayName = currentSession.displayName(fromAudibleMediaSelectionOption: option)
            
            if displayName == selectedOptionDisplayName {
                break
            }
            
            selectionIndex += 1
        }
        
        cell.accessoryType = selectionIndex == indexPath.row ? .checkmark : .none
        
        cell.accessibilityTraits = .button
        let sectionTitle = tableView(theTableView, titleForHeaderInSection: indexPath.section) ?? ""
        cell.accessibilityLabel = "\(sectionTitle), \(displayName)"
        
        cell.backgroundColor = UIColor.blue
        cell.textLabel?.textColor = UIColor.white
        
        return cell
    }
    
    private func legibleCell(forRowAtIndexPath indexPath: IndexPath, tableView theTableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClosedCaptionMenuConfig.CellReuseId)!
        
        guard let legibleMediaOptions = legibleMediaOptions(), let currentSession = currentSession else {
            return cell
        }
        
        if indexPath.row == ClosedCaptionMenuConfig.LegibleOptionsOffItemIndex {
            cell.textLabel?.text = ClosedCaptionMenuConfig.ClosedCaptionMenuOffItemTitle
        } else if indexPath.row == ClosedCaptionMenuConfig.LegibleOptionsAutoItemIndex {
            cell.textLabel?.text = ClosedCaptionMenuConfig.ClosedCaptionMenuAutoItemTitle
        } else {
            let option = legibleMediaOptions[indexPath.row - ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem]
            cell.textLabel?.text = currentSession.displayName(fromLegibleMediaSelectionOption: option)
        }
        
        // the current selection index.
        var selectionIndex = 0
        
        // fetch the current selection option
        let selectedOption = currentSession.selectedLegibleMediaOption

        if let _selectedOption = selectedOption {
            
            // a forced subtitle should only be set by AV Foundation when the user has made no other
            // selection. if the option is a forced subtitle, assume the selection was made Auto'matically.
            if _selectedOption.hasMediaCharacteristic(.containsOnlyForcedSubtitles) {
                selectionIndex = ClosedCaptionMenuConfig.LegibleOptionsAutoItemIndex
            } else {
                
                // the selection is non-nil and unforced so it must be a user selection. find it.
                let selectedOptionDisplayName = currentSession.displayName(fromLegibleMediaSelectionOption: _selectedOption)
                
                var counter = ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem // Offset by 2 due to "Off" and "Auto" rows
                for option in legibleMediaOptions {
                    let displayName = currentSession.displayName(fromLegibleMediaSelectionOption: option)
                    
                    if displayName == selectedOptionDisplayName {
                        break
                    }
                    counter += 1
                }
                
                selectionIndex = counter
                
            }
            
        } else {
            // a nil selection option indicates the Off selection.
            selectionIndex = ClosedCaptionMenuConfig.LegibleOptionsOffItemIndex
        }
        
        cell.accessoryType = selectionIndex == indexPath.row ? .checkmark : .none
        
        cell.accessibilityTraits = .button
        let sectionTitle = tableView(theTableView, titleForHeaderInSection: indexPath.section) ?? ""
        let displayName = cell.textLabel?.text ?? ""
        cell.accessibilityLabel = "\(sectionTitle), \(displayName)"
        
        cell.backgroundColor = UIColor.red
        cell.textLabel?.textColor = UIColor.white
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableViewSectionIsAudibleSection(section) {
            return "AUDIO"
        } else if tableViewSectionIsLegibleSection(section) {
            return "SUBTITLES"
        }
        
        return nil
    }
    
    override func tableView(_ theTableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        headerView.isAccessibilityElement = false
        headerView.textLabel?.text = tableView(theTableView, titleForHeaderInSection: section)
        headerView.textLabel?.isAccessibilityElement = false
        return headerView
    }
    
}

// MARK: - UITableViewDelegate
extension ClosedCaptionMenuController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableViewSectionIsAudibleSection(indexPath.section) {
            didSelectAudibleRowAtIndexPath(tableView, indexPath: indexPath)
        } else if tableViewSectionIsLegibleSection(indexPath.section) {
            didSelectLegibleRowAtIndexPath(tableView, indexPath: indexPath)
        }
        
    }
    
    private func didSelectAudibleRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) {
        
        // update the UI. check the selected and uncheck everything else.
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        for cell in tableView.visibleCells {
            
            guard let indexPath = tableView.indexPath(for: cell) else {
                continue
            }
            
            if tableViewSectionIsAudibleSection(indexPath.section) {
                cell.accessoryType = selectedCell == cell ? .checkmark : .none
            }
            
        }
        
        guard let audibleMediaOptions = audibleMediaOptions() else {
            return
        }
        
        // set the current audible media option.
        let selectedOption = audibleMediaOptions[indexPath.row]
        currentSession?.selectedAudibleMediaOption = selectedOption
        
    }
    
    private func didSelectLegibleRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) {
        
        // update the UI. check the selected and uncheck everything else.
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        for cell in tableView.visibleCells {
            
            guard let indexPath = tableView.indexPath(for: cell) else {
                continue
            }
            
            if tableViewSectionIsLegibleSection(indexPath.section) {
                cell.accessoryType = selectedCell == cell ? .checkmark : .none
            }
            
        }
        
        guard let legibleMediaOptions = legibleMediaOptions() else {
            return
        }
        
        // set the current legible media option.
        switch indexPath.row {
        case ClosedCaptionMenuConfig.LegibleOptionsOffItemIndex: // 0. Off option
            currentSession?.selectedLegibleMediaOption = nil
        case ClosedCaptionMenuConfig.LegibleOptionsAutoItemIndex: // 1. Auto option
            currentSession?.selectLegibleMediaOptionAutomatically()
        default: // other options
            let selectIdx = indexPath.row - ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem
            let option = legibleMediaOptions[selectIdx]
            currentSession?.selectedLegibleMediaOption = option
        }
        
    }
    
}

