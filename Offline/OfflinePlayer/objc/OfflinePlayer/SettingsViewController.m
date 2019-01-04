//
//  SettingsViewController.m
//  OfflinePlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2019 Brightcove. All rights reserved.
//

@import AVFoundation;

#import "SettingsViewController.h"


SettingsViewController *gSettingsViewController;

@interface SettingsViewController ()

// IBOutlets for our UI elements
@property (nonatomic) IBOutlet UITextField *bitrateTextField;
@property (nonatomic) IBOutlet UITextField *rentalDurationTextField;
@property (nonatomic) IBOutlet UIView *rentalSettingsView;
@property (nonatomic) IBOutlet UISegmentedControl *licenseTypeSegmentedControl;

@end


@implementation SettingsViewController


#pragma mark Initialization method

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        gSettingsViewController = self;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Become delegate so we can control orientation
    gVideosViewController.tabBarController.delegate = self;
}

- (UIInterfaceOrientationMask)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setup
{
    [self.licenseTypeSegmentedControl addTarget:self
                                         action:@selector(doLicenseTypeChange:)
                               forControlEvents:UIControlEventValueChanged];
    
    // Add a "Done" button to the numeric keyboard
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(doneClicked:)];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    
    self.bitrateTextField.inputAccessoryView = keyboardDoneButtonView;
    self.rentalDurationTextField.inputAccessoryView = keyboardDoneButtonView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tabBarController = (UITabBarController*)self.parentViewController;

    [self setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
}

- (IBAction)doneClicked:(id)sender
{
    [self.view endEditing:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (BOOL)purchaseLicenseType
{
    if (self.licenseTypeSegmentedControl == nil)
    {
        return NO;
    }

    BOOL isPurchaseLicenseType = (self.licenseTypeSegmentedControl.selectedSegmentIndex == 1);
    
    return isPurchaseLicenseType;
}

- (IBAction)doLicenseTypeChange:(id)sender
{
    BOOL isPurchaseLicenseType = [self purchaseLicenseType];

    self.rentalSettingsView.alpha = (isPurchaseLicenseType ? 0.0 : 1.0);
}

- (long long int)bitrate
{
    if (self.bitrateTextField == nil)
    {
        return 1000000;
    }
    
    long long int bitrate = self.bitrateTextField.text.longLongValue;
    
    return bitrate;
}

- (unsigned long long)rentalDuration
{
    if (self.rentalDurationTextField == nil)
    {
        return 3600;
    }

    unsigned long long durationSeconds = self.rentalDurationTextField.text.longLongValue;
    
    return durationSeconds;
}

- (IBAction)doAllowDownloadsOverCellularSwitch:(UISwitch *)switchControl
{
    NSDictionary *optionsDictionary =
    @{
      kBCOVOfflineVideoManagerAllowsCellularDownloadKey: @(switchControl.on),
      kBCOVOfflineVideoManagerAllowsCellularPlaybackKey: @(switchControl.on),
      kBCOVOfflineVideoManagerAllowsCellularAnalyticsKey: @(switchControl.on)
      };
    
    // Re-initialize with same delegate, but new options.
    [BCOVOfflineVideoManager initializeOfflineVideoManagerWithDelegate:gVideosViewController
                                                               options:optionsDictionary];
}

@end
