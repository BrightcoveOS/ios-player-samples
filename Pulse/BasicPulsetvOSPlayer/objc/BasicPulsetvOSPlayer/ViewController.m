//
//  ViewController.m
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 2/14/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Pulse_tvOS/Pulse.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcovePulse/BrightcovePulse.h>

#import "ViewController.h"


static NSString * const kServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kAccountID = @"5434391461001";
static NSString * const kVideoID = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPulsePlaybackSessionDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) id<BCOVPlaybackSessionProvider> pulseSessionProvider;

@property (nonatomic, strong) BCOVTVPlayerView *playerView;
@property (nonatomic, strong) BCOVVideo *video;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupPlayerView];
    [self setupPlaybackController];
    [self requestVideo];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark Misc

- (void)requestVideo
{
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kServicePolicyKey];
    
    __weak typeof(self) weakSelf = self;
    
    [playbackService findVideoWithVideoID:kVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            [weakSelf.playbackController setVideos:@[ video ] ];

            if (weakSelf.videoItem.extendSession)
            {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                // Delay execution.
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

                    /**
                     * You cannot request insertion points that have been requested already. For example,
                     * if you have already requested post-roll ads, then you cannot request them again.
                     * You can request additional mid-rolls, but only for cue points that have not been
                     * requested yet. For example, if you have already requested mid-rolls to show after 10 seconds
                     * and 30 seconds of video content playback, you can only request more mid-rolls for times that
                     * differ from 10 and 30 seconds.
                     */

                    NSLog(@"Request a session extension for midroll ads at 30th second.");

                    OOContentMetadata *extendContentMetadata = [OOContentMetadata new];
                    extendContentMetadata.tags = @[ @"standard-midrolls" ];

                    OORequestSettings *extendRequestSettings = [OORequestSettings new];
                    extendRequestSettings.linearPlaybackPositions = @[ @30 ];
                    extendRequestSettings.insertionPointFilter = OOInsertionPointTypePlaybackPosition;

                    [(BCOVPulseSessionProvider *)strongSelf.pulseSessionProvider requestSessionExtensionWithContentMetadata:extendContentMetadata requestSettings:extendRequestSettings success:^{

                        NSLog(@"Session was successfully extended. There are now midroll ads at 30th second.");

                    }];
                });
            }
        }
        else
        {
            NSLog(@"PlayerViewController Debug - Error retrieving video");
        }

    }];
}

- (void)setupPlayerView
{
    BCOVTVPlayerViewOptions *options = [[BCOVTVPlayerViewOptions alloc] init];
    options.presentingViewController = self;
    
    self.playerView = [[BCOVTVPlayerView alloc] initWithOptions:options];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.videoContainer addSubview:self.playerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
        [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
        [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
        [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
    ]];
}

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = BCOVPlayerSDKManager.sharedManager;

    // Replace with your own Pulse Host info:
    NSString *pulseHost = @"https://bc-test.videoplaza.tv";

    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
    OOContentMetadata *contentMetadata = [OOContentMetadata new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
    OORequestSettings *requestSettings = [OORequestSettings new];

    NSString *persistentId = [UIDevice.currentDevice.identifierForVendor UUIDString];

    NSDictionary *pulseProperties = @{
        kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
        kBCOVPulseOptionPulsePersistentIdKey: persistentId
    };

    /**
     *  Initialize the Brightcove Pulse Plugin.
     *  Host:
     *      The host is derived from the "sub-domain” found in the Pulse UI and is formulated
     *      like this: `https://[sub-domain].videoplaza.tv`
     *  Device Container (kBCOVPulseOptionPulseDeviceContainerKey):
     *      The device container in Pulse is used for targeting and reporting purposes.
     *      This device container attribute is only used if you want to override the Pulse
     *      device detection algorithm on the Pulse ad server. This should only be set if normal
     *      device detection does not work and only after consulting our personnel.
     *      An incorrect device container value can result in no ads being served
     *      or incorrect ad delivery and reports.
     *  Persistent Id (kBCOVPulseOptionPulsePersistentIdKey):
     *      The persistent identifier is used to identify the end user and is the
     *      basis for frequency capping, uniqueness, DMP targeting information and
     *      more. Use Apple's advertising identifier (IDFA), or your own unique
     *      user identifier here.
     *
     *  Refer to:
     *  https://docs.invidi.com/r/INVIDI-Pulse-Documentation/Pulse-SDKs-parameter-reference
     */

    self.pulseSessionProvider = [manager createPulseSessionProviderWithPulseHost:pulseHost
                                                                 contentMetadata:contentMetadata
                                                                 requestSettings:requestSettings
                                                                     adContainer:self.playerView.contentOverlayView
                                                                  companionSlots:@[]
                                                         upstreamSessionProvider:nil
                                                                         options:pulseProperties];
    
    self.playbackController = [manager createPlaybackControllerWithSessionProvider:self.pulseSessionProvider
                                                                      viewStrategy:nil];

    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    self.playbackController.delegate = self;
    
    self.playerView.playbackController = self.playbackController;
}


#pragma mark BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"Event: %@", lifecycleEvent.eventType);
}


#pragma mark BCOVPulsePlaybackSessionDelegate

- (id<OOPulseSession>)createSessionForVideo:(BCOVVideo *)video withPulseHost:(NSString *)pulseHost contentMetadata:(OOContentMetadata *)contentMetadata requestSettings:(OORequestSettings *)requestSettings
{
    if (!pulseHost) return nil;
    
     // Override the content metadata.
    contentMetadata.category = self.videoItem.category;
    contentMetadata.tags     = self.videoItem.tags;
    
    // Override the request settings.
    requestSettings.linearPlaybackPositions = self.videoItem.midrollPositions;
    
    return [OOPulse sessionWithContentMetadata:contentMetadata requestSettings:requestSettings];
}


#pragma mark UI

// Preferred focus for tvOS 10+
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return (@[ self.playerView.controlsView ?: self ]);
}

@end
