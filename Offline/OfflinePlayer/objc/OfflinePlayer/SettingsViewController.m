//
//  SettingsViewController.m
//  OfflinePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "DownloadManager.h"
#import "SettingsViewController.h"
#import "UITabBarController+OfflinePlayer.h"
#import "VideosViewController.h"


UInt64 const kBitrate = 1000000;
UInt64 const kRentalDuration = 3600;
UInt64 const kPlayDuration = 600;


@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *allowCellularDownloadSwitch;
@property (nonatomic, weak) IBOutlet UITextField *bitrateTextField;
@property (nonatomic, weak) IBOutlet UISegmentedControl *licenseTypeSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField *rentalDurationTextField;
@property (nonatomic, weak) IBOutlet UITextField *playDurationTextField;
@property (nonatomic, weak) IBOutlet UILabel *sdkVersionLabel;

@end


@implementation SettingsViewController

- (BOOL)allowDownloadsOverCellular
{
    return self.allowCellularDownloadSwitch.isOn;
}

- (BOOL)purchaseLicenseType
{
    return self.licenseTypeSegmentedControl.selectedSegmentIndex == 1;
}

- (UInt64)bitrate
{
    if (self.bitrateTextField)
    {
        return self.bitrateTextField.text.longLongValue;
    }

    return kBitrate;
}

- (UInt64)rentalDuration
{
    if (self.rentalDurationTextField)
    {
        return self.rentalDurationTextField.text.longLongValue;
    }

    return kRentalDuration;
}

- (UInt64)playDuration
{
    if (self.playDurationTextField)
    {
        return self.playDurationTextField.text.longLongValue;
    }

    return kPlayDuration;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.sdkVersionLabel.text = [NSString stringWithFormat:@"BrightcovePlayerSDK v%ld",
                                 BCOVPlayerSDKManager.version];

#if TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST
    self.allowCellularDownloadSwitch.enabled = NO;
#else
    [self.allowCellularDownloadSwitch addTarget:self
                                         action:@selector(doAllowDownloadsOverCellular:)
                               forControlEvents:UIControlEventValueChanged];
#endif

    [self.licenseTypeSegmentedControl addTarget:self
                                         action:@selector(doLicenseTypeChange)
                               forControlEvents:UIControlEventValueChanged];

    UIToolbar *keyboardDoneButtonView = ({
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleDone
                                                                      target:self
                                                                      action:@selector(doneClicked)];

        UIToolbar *keyboardDoneButtonView = [UIToolbar new];
        [keyboardDoneButtonView setItems:@[doneButton]
                                animated:YES];
        [keyboardDoneButtonView sizeToFit];
        keyboardDoneButtonView;
    });

    self.bitrateTextField.text = [NSString stringWithFormat:@"%llu", kBitrate];
    self.bitrateTextField.inputAccessoryView = keyboardDoneButtonView;

    self.rentalDurationTextField.text = [NSString stringWithFormat:@"%llu", kRentalDuration];
    self.rentalDurationTextField.inputAccessoryView = keyboardDoneButtonView;

    self.playDurationTextField.text = [NSString stringWithFormat:@"%llu", kPlayDuration];
    self.playDurationTextField.inputAccessoryView = keyboardDoneButtonView;

    [self doLicenseTypeChange];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.view endEditing:YES];
}

#if !TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST
- (void)doAllowDownloadsOverCellular:(UISwitch *)sender
{
    NSNumber *isOn = [NSNumber numberWithBool:sender.isOn];

    NSDictionary *options = @{
        kBCOVOfflineVideoManagerAllowsCellularDownloadKey: isOn,
        kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: isOn,
        kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: isOn
    };

    // Re-initialize with same delegate, but new options.
    [BCOVOfflineVideoManager initializeOfflineVideoManagerWithDelegate:DownloadManager.shared
                                                               options:options];
}
#endif

- (void)doLicenseTypeChange
{
    self.rentalDurationTextField.enabled = !self.purchaseLicenseType;
    self.playDurationTextField.enabled = self.purchaseLicenseType;
}

- (void)doneClicked
{
    [self.view endEditing:YES];
}

@end
