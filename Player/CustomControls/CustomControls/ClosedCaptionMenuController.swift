//
//  ClosedCaptionMenuController.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
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


final class ClosedCaptionMenuController: UITableViewController {

    weak var controlsView: ControlsViewController?
    weak var currentSession: BCOVPlaybackSession? {
        didSet {
            if let controlsView {
                DispatchQueue.global(qos: .background).async { [self] in
                    // new session. (re)build a list of the sections of the media option table view.
                    var mediaOptionTypes = [AVMediaCharacteristic]()

                    if audibleMediaOptions.count > 1 {
                        mediaOptionTypes.append(AVMediaCharacteristic.audible)
                    }

                    if legibleMediaOptions.count > 0 {
                        mediaOptionTypes.append(AVMediaCharacteristic.legible)
                    }

                    DispatchQueue.main.async { [self] in
                        // Save an immutable copy.
                        // Do this on main thread to prevent concurrency problems.
                        mediaOptionsTableViewSectionList = mediaOptionTypes

                        // Enable closed caption button if there are closed captions OR more than 1 soundtrack.
                        // Do this on main thread because closedCaptionEnabled changes the UI.
                        let closedCaptionEnabled = legibleMediaOptions.count > 0 || audibleMediaOptions.count > 1
                        controlsView.closedCaptionEnabled = closedCaptionEnabled
                    }
                }
            }
        }
    }

    // sort the options in order of preferred language.
    fileprivate lazy var sortDescriptor = {
        [self] (obj1: Any, obj2: Any) -> ComparisonResult in

        guard let option1 = obj1 as? AVMediaSelectionOption,
              let option2 = obj2 as? AVMediaSelectionOption else {
            return .orderedSame
        }

        let option1LocaleIdentifier = option1.locale?.identifier ?? ""
        let option2LocaleIdentifier = option2.locale?.identifier ?? ""

        let localeKey = NSLocale.Key.languageCode.rawValue

        guard let codes1 = NSLocale.components(fromLocaleIdentifier: option1LocaleIdentifier)[localeKey],
              let codes2 = NSLocale.components(fromLocaleIdentifier: option2LocaleIdentifier)[localeKey] else {
            return .orderedSame
        }

        // set up the sort order. boil the language IDs down to their language codes (en, instead of en_US).
        var preferredLanguageCodes: [String] = .init()
        for aLanguage in NSLocale.preferredLanguages {
            guard let theLanguageCode = NSLocale.components(fromLocaleIdentifier: aLanguage)[NSLocale.Key.languageCode.rawValue] else {
                continue
            }

            if !theLanguageCode.isEmpty {
                preferredLanguageCodes.append(theLanguageCode)
            }
        }

        var indexOfObj1 = preferredLanguageCodes.firstIndex(of: codes1) ?? NSNotFound
        if indexOfObj1 == NSNotFound {
            indexOfObj1 = Int.max
        }

        var indexOfObj2 = preferredLanguageCodes.firstIndex(of: codes2) ?? NSNotFound
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

    fileprivate lazy var audibleMediaOptions: [AVMediaSelectionOption] = {
        guard let currentSession,
              let soundtrackGroup = currentSession.audibleMediaSelectionGroup else { return [] }

        let options = soundtrackGroup.options
        let playableSoundtracks = AVMediaSelectionGroup.playableMediaSelectionOptions(from: options)

        let sortedPlayableSoundtracks = (playableSoundtracks as NSArray).sortedArray(comparator: sortDescriptor)

        return sortedPlayableSoundtracks as? [AVMediaSelectionOption] ?? []
    }()

    fileprivate lazy var legibleMediaOptions: [AVMediaSelectionOption] = {
        guard let currentSession,
              let legibleGroup = currentSession.legibleMediaSelectionGroup else {
            return []
        }

        // construct a list of subtitles and closed captions with valid locales.
        var validLegibleOptions = [AVMediaSelectionOption]()
        for option in legibleGroup.options {
            if option.mediaType == .subtitle ||
                option.mediaType == .closedCaption {
                validLegibleOptions.append(option)
            }
        }

        // return the list of playable, unforced subtitles & closed captions. refer
        // to "Advice about subtitles" in "AV Foundation Release Notes for iOS 5".
        // https://developer.apple.com/library/prerelease/mac/releasenotes/AudioVideo/RN-AVFoundation/index.html#//apple_ref/doc/uid/TP40010717-CH1-DontLinkElementID_3

        let playableLegibleOptions = AVMediaSelectionGroup.playableMediaSelectionOptions(from: validLegibleOptions)
        let unforcedLegibleOptions = AVMediaSelectionGroup.mediaSelectionOptions(from: playableLegibleOptions,
                                                                                 withoutMediaCharacteristics: [.containsOnlyForcedSubtitles])

        // sort the options in order of preferred language.
        let sortedLegibleOptions = (unforcedLegibleOptions as NSArray).sortedArray(comparator: sortDescriptor)

        return sortedLegibleOptions as? [AVMediaSelectionOption] ?? []
    }()

    // a description of the sections of the media selection table view.
    fileprivate var mediaOptionsTableViewSectionList: [AVMediaCharacteristic]?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let player = currentSession?.player {
            player.pause()
        }

        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Audio & Subtitles"

        tableView.register(UITableViewCell.classForCoder(),
                           forCellReuseIdentifier: ClosedCaptionMenuConfig.CellReuseId)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(doneButtonPressed(_:)))
    }

    @objc
    fileprivate func doneButtonPressed(_ button: UIButton) {
        guard let currentSession,
              let presentingViewController else { return }

        presentingViewController.dismiss(animated: true) {
            currentSession.player.play()
        }
    }
}


// MARK: - UITableViewDataSource

extension ClosedCaptionMenuController {

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if tableViewSectionIsAudibleSection(section) {
            return audibleMediaOptions.count
        } else if tableViewSectionIsLegibleSection(section) {
            return legibleMediaOptions.count + ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem
        }

        return 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableViewSectionIsAudibleSection(indexPath.section),
           let cell = audibleCell(forRowAtIndexPath: indexPath,
                                  tableView: tableView) {
            return cell
        } else if tableViewSectionIsLegibleSection(indexPath.section),
                  let cell = legibleCell(forRowAtIndexPath: indexPath,
                                         tableView: tableView) {
            return cell
        }

        return UITableViewCell()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let mediaOptionsTableViewSectionList else {
            return 0
        }

        return mediaOptionsTableViewSectionList.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if tableViewSectionIsAudibleSection(section) {
            return "AUDIO"
        } else if tableViewSectionIsLegibleSection(section) {
            return "SUBTITLES"
        }

        return nil
    }

    override func tableView(_ theTableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        headerView.isAccessibilityElement = false
        headerView.textLabel?.text = tableView(theTableView,
                                               titleForHeaderInSection: section)
        headerView.textLabel?.isAccessibilityElement = false
        return headerView
    }

    fileprivate func tableViewSectionIsAudibleSection(_ section:  Int) -> Bool {
        guard let mediaOptionsTableViewSectionList else {
            return false
        }

        return mediaOptionsTableViewSectionList[section] == AVMediaCharacteristic.audible
    }

    fileprivate func tableViewSectionIsLegibleSection(_ section:  Int) -> Bool {
        guard let mediaOptionsTableViewSectionList else {
            return false
        }

        return mediaOptionsTableViewSectionList[section] == AVMediaCharacteristic.legible
    }

    fileprivate func audibleCell(forRowAtIndexPath indexPath: IndexPath,
                                 tableView theTableView: UITableView) -> UITableViewCell? {
        guard let currentSession,
              let cell = tableView.dequeueReusableCell(withIdentifier: ClosedCaptionMenuConfig.CellReuseId) else {
            return nil
        }

        let option = audibleMediaOptions[indexPath.row]
        let displayName = currentSession.displayName(fromAudibleMediaSelectionOption: option) ?? ""
        cell.textLabel?.text = displayName

        // add a checkmark to the selected cell.
        let selectedOption = currentSession.selectedAudibleMediaOption

        // what's the index of the selectedOption?
        let selectedOptionDisplayName = currentSession.displayName(fromAudibleMediaSelectionOption: selectedOption)

        let selectionIndex = audibleMediaOptions.firstIndex(where: { currentSession.displayName(fromAudibleMediaSelectionOption: $0) == selectedOptionDisplayName })
        cell.accessoryType = selectionIndex == indexPath.row ? .checkmark : .none

        cell.accessibilityTraits = .button
        let sectionTitle = tableView(theTableView,
                                     titleForHeaderInSection: indexPath.section) ?? ""
        cell.accessibilityLabel = "\(sectionTitle), \(displayName)"

        cell.backgroundColor = .systemBlue.withAlphaComponent(0.75)
        cell.textLabel?.textColor = .white

        return cell
    }

    fileprivate func legibleCell(forRowAtIndexPath indexPath: IndexPath,
                                 tableView theTableView: UITableView) -> UITableViewCell? {
        guard let currentSession,
              let cell = tableView.dequeueReusableCell(withIdentifier: ClosedCaptionMenuConfig.CellReuseId) else {
            return nil
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
        if let selectedOption = currentSession.selectedLegibleMediaOption {
            // a forced subtitle should only be set by AV Foundation when the user has made no other
            // selection. if the option is a forced subtitle, assume the selection was made Auto'matically.
            if selectedOption.hasMediaCharacteristic(.containsOnlyForcedSubtitles) {
                selectionIndex = ClosedCaptionMenuConfig.LegibleOptionsAutoItemIndex
            } else {
                // the selection is non-nil and unforced so it must be a user selection. find it.
                let selectedOptionDisplayName = currentSession.displayName(fromLegibleMediaSelectionOption: selectedOption)
                selectionIndex = legibleMediaOptions.firstIndex(where: { currentSession.displayName(fromLegibleMediaSelectionOption: $0) == selectedOptionDisplayName }) ?? 0
            }
        } else {
            // a nil selection option indicates the Off selection.
            selectionIndex = ClosedCaptionMenuConfig.LegibleOptionsOffItemIndex
        }

        cell.accessoryType = selectionIndex == (indexPath.row - ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem) ? .checkmark : .none

        cell.accessibilityTraits = .button
        let sectionTitle = tableView(theTableView,
                                     titleForHeaderInSection: indexPath.section) ?? ""
        let displayName = cell.textLabel?.text ?? ""
        cell.accessibilityLabel = "\(sectionTitle), \(displayName)"

        cell.backgroundColor = .systemRed.withAlphaComponent(0.75)
        cell.textLabel?.textColor = .white

        return cell
    }
}


// MARK: - UITableViewDelegate

extension ClosedCaptionMenuController {

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if tableViewSectionIsAudibleSection(indexPath.section) {
            didSelectAudibleRowAtIndexPath(tableView, indexPath: indexPath)
        } else if tableViewSectionIsLegibleSection(indexPath.section) {
            didSelectLegibleRowAtIndexPath(tableView, indexPath: indexPath)
        }
    }

    fileprivate func didSelectAudibleRowAtIndexPath(_ tableView: UITableView,
                                                    indexPath: IndexPath) {
        // Update the UI. Check the selected and uncheck everything else.
        let selectedCell = tableView.cellForRow(at: indexPath)

        for cell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell) else {
                continue
            }

            if tableViewSectionIsAudibleSection(indexPath.section) {
                cell.accessoryType = selectedCell == cell ? .checkmark : .none
            }
        }

        if let currentSession {
            // set the current audible media option.
            let selectedOption = audibleMediaOptions[indexPath.row]
            currentSession.selectedAudibleMediaOption = selectedOption
        }
    }

    fileprivate func didSelectLegibleRowAtIndexPath(_ tableView: UITableView,
                                                    indexPath: IndexPath) {

        // Update the UI. Check the selected and uncheck everything else.
        let selectedCell = tableView.cellForRow(at: indexPath)

        for cell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell) else {
                continue
            }

            if tableViewSectionIsLegibleSection(indexPath.section) {
                cell.accessoryType = selectedCell == cell ? .checkmark : .none
            }
        }

        if let currentSession {
            // set the current legible media option.
            switch indexPath.row {
                case ClosedCaptionMenuConfig.LegibleOptionsOffItemIndex: // 0. Off option
                    currentSession.selectedLegibleMediaOption = nil
                case ClosedCaptionMenuConfig.LegibleOptionsAutoItemIndex: // 1. Auto option
                    currentSession.selectLegibleMediaOptionAutomatically()
                default: // other options
                    let selectIdx = indexPath.row - ClosedCaptionMenuConfig.LegibleOptionsOffsetFromOffItem
                    let option = legibleMediaOptions[selectIdx]
                    currentSession.selectedLegibleMediaOption = option
            }
        }
    }
}
