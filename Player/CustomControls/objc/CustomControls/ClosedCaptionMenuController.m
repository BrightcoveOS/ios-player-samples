//
//  ClosedCaptionMenuController.m
//  CustomControls
//
//  Created by Jeremy Blaker on 2/26/21.
//  Copyright © 2021 Brightcove. All rights reserved.
//

#import "ClosedCaptionMenuController.h"
#import "ControlsViewController.h"

@import AVFoundation;
@import BrightcovePlayerSDK;

// legible media options follow the menu items "Off" and "Auto".
static const NSUInteger kLegibleOptionsOffItemIndex = 0;
static const NSUInteger kLegibleOptionsAutoItemIndex = 1;
static const NSUInteger kLegibleOptionsOffsetFromOffItem = 2;

static NSString * const kCellReuseId = @"ClosedCaptionCell";
static NSString * const kClosedCaptionMenuOffItemTitle = @"Off";
static NSString * const kClosedCaptionMenuAutoItemTitle = @"Auto";

@interface ClosedCaptionMenuController ()

// a description of the sections of the media selection table view.
@property (nonatomic, strong) NSArray<NSString *> *mediaOptionsTableViewSectionList;

@end

@implementation ClosedCaptionMenuController

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.currentSession.player pause];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kCellReuseId];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(cancelButtonPressed:)];
}

#pragma mark - UI Actions

- (void)cancelButtonPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.currentSession.player play];
    }];
}

#pragma mark - Getters

- (NSArray<AVMediaSelectionOption *> *)audibleMediaOptions
{
    // return the list of playable soundtracks.

    NSArray<AVMediaSelectionOption *> *playableSoundtracks;
    
    AVMediaSelectionGroup *soundtrackGroup = self.currentSession.audibleMediaSelectionGroup;
    playableSoundtracks = [AVMediaSelectionGroup playableMediaSelectionOptionsFromArray:soundtrackGroup.options];
    
    // set up the sort order. boil the language IDs down to their language codes (en, instead of en_US).
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    NSMutableArray<NSString *> *preferredLanguageCodes = [[NSMutableArray alloc] init];
    for (NSString *aLanguage in preferredLanguages)
    {
        NSString *theLanguageCode = [NSLocale componentsFromLocaleIdentifier:aLanguage][NSLocaleLanguageCode];
        if (theLanguageCode)
        {
            [preferredLanguageCodes addObject:theLanguageCode];
        }
    }
    
    // sort the options in order of preferred language.
    NSArray<AVMediaSelectionOption *> *sortedPlayableSoundtracks = [playableSoundtracks sortedArrayUsingComparator:^NSComparisonResult(AVMediaSelectionOption * _Nonnull obj1, AVMediaSelectionOption * _Nonnull obj2) {
        
        NSUInteger indexOfObj1 = [preferredLanguageCodes indexOfObject:[NSLocale componentsFromLocaleIdentifier:obj1.locale.localeIdentifier][NSLocaleLanguageCode]];
        if (indexOfObj1 == NSNotFound)
        {
            indexOfObj1 = NSUIntegerMax;
        }
        
        NSUInteger indexOfObj2 = [preferredLanguageCodes indexOfObject:[NSLocale componentsFromLocaleIdentifier:obj2.locale.localeIdentifier][NSLocaleLanguageCode]];
        if (indexOfObj2 == NSNotFound)
        {
            indexOfObj2 = NSUIntegerMax;
        }
        
        if (indexOfObj2 > indexOfObj1)
        {
            return NSOrderedAscending;
        }
        
        if (indexOfObj2 < indexOfObj1)
        {
            return NSOrderedDescending;
        }
        
        // neither item was in the list of user language prefs so apply a simple sort.
        return [obj1.displayName caseInsensitiveCompare:obj2.displayName];
    }];
    
    return sortedPlayableSoundtracks;
}

- (NSArray<AVMediaSelectionOption *> *)legibleMediaOptions
{
    // return the list of playable, unforced subtitles & closed captions. refer
    // to "Advice about subtitles" in "AV Foundation Release Notes for iOS 5".
    // https://developer.apple.com/library/prerelease/mac/releasenotes/AudioVideo/RN-AVFoundation/index.html#//apple_ref/doc/uid/TP40010717-CH1-DontLinkElementID_3
    
    NSArray<AVMediaSelectionOption *> *unforcedLegibleOptions;
    
    AVMediaSelectionGroup *legibleGroup = self.currentSession.legibleMediaSelectionGroup;

    // construct a list of subtitles and closed captions with valid locales.
    NSMutableArray<AVMediaSelectionOption *> *validLegibleOptions = [[NSMutableArray alloc] init];
    for (AVMediaSelectionOption *option in legibleGroup.options)
    {
        if (([option.mediaType isEqualToString:AVMediaTypeSubtitle] || [option.mediaType isEqualToString:AVMediaTypeClosedCaption]))
        {
            [validLegibleOptions addObject:option];
        }
    }
    
    // make sure they're playable and unforced.
    NSArray<AVMediaSelectionOption *> *playableLegibleOptions = [AVMediaSelectionGroup playableMediaSelectionOptionsFromArray:validLegibleOptions];
    unforcedLegibleOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:playableLegibleOptions withoutMediaCharacteristics:@[ AVMediaCharacteristicContainsOnlyForcedSubtitles ]];
    
    // define the sort order. boil the language IDs down to their language codes (en, instead of en_US).
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    NSMutableArray<NSString *> *preferredLanguageCodes = [[NSMutableArray alloc] init];
    for (NSString *aLanguage in preferredLanguages)
    {
        NSString *theLanguageCode = [NSLocale componentsFromLocaleIdentifier:aLanguage][NSLocaleLanguageCode];
        if (theLanguageCode)
        {
            [preferredLanguageCodes addObject:theLanguageCode];
        }
    }

    // sort the options in order of preferred language.
    NSArray<AVMediaSelectionOption *> *sortedLegibleOptions = [unforcedLegibleOptions sortedArrayUsingComparator:^NSComparisonResult(AVMediaSelectionOption * _Nonnull obj1, AVMediaSelectionOption * _Nonnull obj2) {
        
        NSUInteger indexOfObj1 = [preferredLanguageCodes indexOfObject:[NSLocale componentsFromLocaleIdentifier:obj1.locale.localeIdentifier][NSLocaleLanguageCode]];
        if (indexOfObj1 == NSNotFound)
        {
            indexOfObj1 = NSUIntegerMax;
        }
        
        NSUInteger indexOfObj2 = [preferredLanguageCodes indexOfObject:[NSLocale componentsFromLocaleIdentifier:obj2.locale.localeIdentifier][NSLocaleLanguageCode]];
        if (indexOfObj2 == NSNotFound)
        {
            indexOfObj2 = NSUIntegerMax;
        }
        
        if (indexOfObj2 > indexOfObj1)
        {
            return NSOrderedAscending;
        }
        
        if (indexOfObj2 < indexOfObj1)
        {
            return NSOrderedDescending;
        }
        
        // neither item was in the list of user language prefs so apply a simple string comparison.
        return [obj1.displayName caseInsensitiveCompare:obj2.displayName];
    }];

    return sortedLegibleOptions;
}

#pragma mark - Setters

- (void)setCurrentSession:(id<BCOVPlaybackSession>)currentSession
{
    _currentSession = currentSession;
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        // new session. (re)build a list of the sections of the media option table view.
        NSMutableArray *mediaOptionTypes = [[NSMutableArray alloc] init];
        
        if (strongSelf.audibleMediaOptions.count > 1)
        {
            [mediaOptionTypes addObject:AVMediaCharacteristicAudible];
        }
        
        if (strongSelf.legibleMediaOptions.count > 0)
        {
            [mediaOptionTypes addObject:AVMediaCharacteristicLegible];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf) strongSelf2 = weakSelf;
            
            // Save an immutable copy.
            // Do this on main thread to prevent concurrency problems.
            strongSelf2.mediaOptionsTableViewSectionList = [NSArray arrayWithArray:mediaOptionTypes];
            
            // Enable closed caption button if there are closed captions OR more than 1 soundtrack.
            // Do this on main thread because closedCaptionEnabled changes the UI.
            BOOL closedCaptionEnabled = (strongSelf2.legibleMediaOptions.lastObject || (strongSelf2.audibleMediaOptions.count > 1));
            strongSelf2.controlsView.closedCaptionEnabled = closedCaptionEnabled;
        });
        
    });
}

#pragma mark - Helpers

- (BOOL)tableViewSectionIsAudibleSection:(NSUInteger)section
{
    return ([self.mediaOptionsTableViewSectionList[section] isEqualToString:AVMediaCharacteristicAudible]);
}

- (BOOL)tableViewSectionIsLegibleSection:(NSUInteger)section
{
    return ([self.mediaOptionsTableViewSectionList[section] isEqualToString:AVMediaCharacteristicLegible]);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.mediaOptionsTableViewSectionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self tableViewSectionIsAudibleSection:section])
    {
        return self.audibleMediaOptions.count;
    }
    else if ([self tableViewSectionIsLegibleSection:section])
    {
        return self.legibleMediaOptions.count + kLegibleOptionsOffsetFromOffItem;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.mediaOptionsTableViewSectionList[indexPath.section] isEqualToString:AVMediaCharacteristicAudible])
    {
        return [self tableView:tableView audibleCellForRowAtIndexPath:indexPath];
    }
    else if ([self.mediaOptionsTableViewSectionList[indexPath.section] isEqualToString:AVMediaCharacteristicLegible])
    {
        return [self tableView:tableView legibleCellForRowAtIndexPath:indexPath];
    }

    return [UITableViewCell new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView audibleCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (self.audibleMediaOptions.count > 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseId forIndexPath:indexPath];
    }
    
    if (cell)
    {
        NSArray *audibleMediaOptions = self.audibleMediaOptions;

        AVMediaSelectionOption *option = audibleMediaOptions[indexPath.row];
        cell.textLabel.text = [self.currentSession displayNameFromAudibleMediaSelectionOption:option];
    
        // add a checkmark to the selected cell.
        AVMediaSelectionOption *selectedOption = self.currentSession.selectedAudibleMediaOption;
        
        // what's the index of the selectedOption?
        NSString *selectedOptionDisplayName = [self.currentSession displayNameFromAudibleMediaSelectionOption:selectedOption];
        
        int selectionIndex = 0;
        for (AVMediaSelectionOption *option in audibleMediaOptions)
        {
            if ([selectedOptionDisplayName isEqualToString:[self.currentSession displayNameFromAudibleMediaSelectionOption:option]])
            {
                break;
            }
            selectionIndex += 1;
        }
        
        cell.accessoryType = ((selectionIndex == indexPath.row)
                              ? UITableViewCellAccessoryCheckmark
                              : UITableViewCellAccessoryNone);
    }

    cell.accessibilityTraits = UIAccessibilityTraitButton;
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", [self tableView:tableView titleForHeaderInSection:indexPath.section], cell.textLabel.text];
    
    cell.backgroundColor = [UIColor blueColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView legibleCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // construct a list of option titles.
    UITableViewCell *cell = nil;
    
    if (self.legibleMediaOptions.count > 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseId forIndexPath:indexPath];
    }
    
    if (cell)
    {
        NSArray *legibleMediaOptions = self.legibleMediaOptions;
        
        if (indexPath.row == kLegibleOptionsOffItemIndex)
        {
            cell.textLabel.text = kClosedCaptionMenuOffItemTitle;
        }
        else if (indexPath.row == kLegibleOptionsAutoItemIndex)
        {
            cell.textLabel.text = kClosedCaptionMenuAutoItemTitle;
        }
        else
        {
            AVMediaSelectionOption *option = legibleMediaOptions[indexPath.row-kLegibleOptionsOffsetFromOffItem];
            cell.textLabel.text = [self.currentSession displayNameFromLegibleMediaSelectionOption:option];
        }
        
        // the current selection index.
        NSNumber *selectionIndex;
        
        // fetch the current selection option;
        AVMediaSelectionOption *selectedOption = self.currentSession.selectedLegibleMediaOption;
        
        if (selectedOption == nil)
        {
            // a nil selection option indicates the Off selection.
            selectionIndex = @(kLegibleOptionsOffItemIndex);
        }
        else
        {
            // a forced subtitle should only be set by AV Foundation when the user has made no other
            // selection. if the option is a forced subtitle, assume the selection was made Auto'matically.
            if ([selectedOption hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles])
            {
                selectionIndex = @(kLegibleOptionsAutoItemIndex);
            }
            else
            {
                // the selection is non-nil and unforced so it must be a user selection. find it.
                NSString *selectedOptionDisplayName = [self.currentSession displayNameFromLegibleMediaSelectionOption:selectedOption];
                
                int counter = kLegibleOptionsOffsetFromOffItem; // Offset by 2 due to "Off" and "Auto" rows
                for (AVMediaSelectionOption *option in legibleMediaOptions)
                {
                    if ([selectedOptionDisplayName isEqualToString:[self.currentSession displayNameFromAudibleMediaSelectionOption:option]])
                    {
                        break;
                    }
                    counter += 1;
                }
                
                selectionIndex = @(counter);
                
            }
        }
        
        cell.accessoryType = ((selectionIndex.integerValue == indexPath.row)
                              ? UITableViewCellAccessoryCheckmark
                              : UITableViewCellAccessoryNone);
    }
    
    cell.accessibilityTraits = UIAccessibilityTraitButton;
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", [self tableView:tableView titleForHeaderInSection:indexPath.section], cell.textLabel.text];

    cell.backgroundColor = [UIColor redColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerView = [UITableViewHeaderFooterView new];
    headerView.isAccessibilityElement = NO;
    headerView.textLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    headerView.textLabel.isAccessibilityElement = NO;
    return headerView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self tableViewSectionIsAudibleSection:section])
    {
        return @"AUDIO";
    }
    else if ([self tableViewSectionIsLegibleSection:section])
    {
        return @"SUBTITLES";
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.mediaOptionsTableViewSectionList[indexPath.section] isEqualToString:AVMediaCharacteristicAudible])
    {
        [self tableView:tableView didSelectAudibleRowAtIndexPath:indexPath];
    }
    else if ([self.mediaOptionsTableViewSectionList[indexPath.section] isEqualToString:AVMediaCharacteristicLegible])
    {
        [self tableView:tableView didSelectLegibleRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectAudibleRowAtIndexPath:(NSIndexPath *)indexPath
{
    // update the UI. check the selected and uncheck everything else.
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    [[tableView visibleCells] enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([self tableViewSectionIsAudibleSection:[tableView indexPathForCell:obj].section])
        {
            obj.accessoryType = ((selectedCell == obj)
                                 ? UITableViewCellAccessoryCheckmark
                                 : UITableViewCellAccessoryNone);
        }
        
    }];
    
    // set the current audible media option.
    AVMediaSelectionOption *selectedOption = self.audibleMediaOptions[indexPath.row];
    self.currentSession.selectedAudibleMediaOption = selectedOption;
}

- (void)tableView:(UITableView *)tableView didSelectLegibleRowAtIndexPath:(NSIndexPath *)indexPath
{
    // update the UI. check the selected and uncheck everything else.
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    [[tableView visibleCells] enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        if ([self tableViewSectionIsLegibleSection:[tableView indexPathForCell:obj].section])
        {
            obj.accessoryType = ((selectedCell == obj)
                                 ? UITableViewCellAccessoryCheckmark
                                 : UITableViewCellAccessoryNone);
        }

    }];

    // set the current legible media option.
    switch (indexPath.row)
    {
        case kLegibleOptionsOffItemIndex:   // 0. Off option
        {
            self.currentSession.selectedLegibleMediaOption = nil;
            break;
        }
            
        case kLegibleOptionsAutoItemIndex: // 1. Auto option
        {
            [self.currentSession selectLegibleMediaOptionAutomatically];
            break;
        }

        default:                                // other options
        {
            NSUInteger offsetFromOffOption = kLegibleOptionsOffsetFromOffItem;
            NSInteger selectIdx = indexPath.row - offsetFromOffOption;
            AVMediaSelectionOption *option = self.legibleMediaOptions[selectIdx];
            self.currentSession.selectedLegibleMediaOption = option;
            break;
        }
    }
}

@end
