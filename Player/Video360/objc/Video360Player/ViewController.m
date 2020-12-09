//
//  ViewController.m
//  Video360Player
//
//  Created by Steve Bushell on 12/22/16.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve and play a 360 video.
 * The code for retrieving and playing the video is identical
 * to any other code that retrieves and plays a video from Video Cloud.
 *
 * What makes this code different is the usage of the
 * BCOVPUIPlayerViewDelegate delegate method
 * `-didSetVideo360NavigationMethod:projectionStyle:`
 * This method is called when the Video 360 button is tapped, and indicates that
 * you probably want to set the device orientation to landscape if the
 * projection method has changed to VR Goggles mode.
 *
 * The code below shows how to handle changing the device orientation
 * when that delegate is called.
 */

@import BrightcovePlayerSDK;

#import "ViewController.h"

// ** Customize these values with your own account information **
static NSString * const kSampleVideoCloudPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kSampleVideoCloudAccountID = @"5434391461001";
static NSString * const kSampleVideo360VideoID = @"1685628526640737870";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic) BCOVPlaybackService *playbackService;
@property (nonatomic) NSObject<BCOVPlaybackController> *playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;

@property (nonatomic) BOOL landscapeOnly; // used to restrict device orientation

@end


@implementation ViewController

#pragma mark Setup Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create Player View (PlayerUI)
    [self createPlayerView];
    
    // Create Playback Controller
    {
        BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
        
        self.playbackController = [sdkManager createPlaybackController];
        self.playbackController.delegate = self;
        self.playbackController.autoAdvance = YES;
        self.playbackController.autoPlay = YES;
        self.playerView.playbackController = self.playbackController;
    }
    
    // Instantiate Playback Service
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kSampleVideoCloudAccountID
                                                                policyKey:kSampleVideoCloudPlaybackServicePolicyKey];
    
    [self requestContentFromPlaybackService];
}

- (void)createPlayerView
{
    if (self.playerView == nil)
    {
        // Create PlayerUI views with normal VOD controls.
        BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
        self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil // can set this later
                                                                        options:nil
                                                                   controlsView:controlView];
        
        // Add to parent view
        [self.videoContainerView addSubview:self.playerView];
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
                                                  [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
                                                  [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
                                                  [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
                                                  ]];
        
        // Receive delegate method callbacks
        self.playerView.delegate = self;
    }
}

- (void)requestContentFromPlaybackService
{
    [self.playbackService findVideoWithVideoID:kSampleVideo360VideoID
                                    parameters:nil
                                    completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
                                        
                                        if (video)
                                        {
                                            // Check "projection" property to confirm that this is a 360 degree video
                                            NSString *projectionPropertyString = video.properties[kBCOVVideoPropertyKeyProjection];
                                            
                                            if (projectionPropertyString
                                                && [projectionPropertyString isEqualToString:@"equirectangular"])
                                            {
                                                NSLog(@"Retrieved a 360 video");
                                            }
                                            
                                            [self.playbackController setVideos:@[ video ]];
                                        }
                                        else
                                        {
                                            NSLog(@"Error retrieving video: %@", error);
                                        }
                                        
                                    }];
}


#pragma mark - UIViewController overrides

// UIViewController overrides that lets us control the orientation of the device
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.landscapeOnly)
    {
        return UIInterfaceOrientationMaskLandscape;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}


#pragma mark - BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    // Play it again
    [controller setVideos:playlist];
}


#pragma mark - BCOVPUIPlayerViewDelegate Methods

- (void)didSetVideo360NavigationMethod:(BCOVPUIVideo360NavigationMethod)navigationMethod
                       projectionStyle:(BCOVVideo360ProjectionStyle)projectionStyle
{
    // This method is called when the Video 360 button is tapped.
    // Use this notification to force an orientation change for the VR Goggles projection style.
    
    switch (projectionStyle)
    {
        case BCOVVideo360ProjectionStyleNormal:
        {
            NSLog(@"projectionStyle == BCOVVideo360ProjectionStyleNormal");
            
            // No landscape restriction
            self.landscapeOnly = NO;
            
            // If the goggles are off, change the device orientation
            // and exit full-screen
            [self.playerView performScreenTransitionWithScreenMode:BCOVPUIScreenModeNormal];
            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            break;
        }
            
        case BCOVVideo360ProjectionStyleVRGoggles:
        {
            NSLog(@"projectionStyle == BCOVVideo360ProjectionStyleVRGoggles");
            
            // Allow only landscape if wearing goggles
            self.landscapeOnly = YES;
            
            // If the goggles are on, change the device orientation
            UIDeviceOrientation currentDeviceOrientation = [UIDevice currentDevice].orientation;
            switch (currentDeviceOrientation)
            {
                case UIDeviceOrientationLandscapeLeft:
                case UIDeviceOrientationLandscapeRight:
                    // already landscape
                    break;
                    
                default:
                {
                    // switch orientation
                    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
                    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
                    break;
                }
            }
            
            break;
        }
    }
    
    [UIViewController attemptRotationToDeviceOrientation];
}

@end
