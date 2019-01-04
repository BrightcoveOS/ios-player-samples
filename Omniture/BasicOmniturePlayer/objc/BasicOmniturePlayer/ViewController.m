//
//  ViewController.m
//  BCOVOmniturePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

// Adobe Media Heartbeat
#import "ADBMediaHeartbeat.h"
#import "ADBMediaHeartbeatConfig.h"

// Adobe Mobile Marketing Cloud
#import "ADBMobile.h"

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVAMCSessionConsumerHeartbeatDelegate, BCOVAMCSessionConsumerMeidaDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic) BCOVPUIPlayerView *playerView;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    _playbackController = [manager createPlaybackControllerWithViewStrategy:nil];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = NO;

    // Use Adobe Video Media Heartbeat v2.0 analytics
    [_playbackController addSessionConsumer: [self videoHeartbeatSessionConsumer]];
    // OR use Adobe media analytics
//    [_playbackController addSessionConsumer: [self mediaAnalyticsSessionConsumer]];

    
    _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
															policyKey:kViewControllerPlaybackServicePolicyKey];
    
}


#pragma mark BCOVAMCSessionConsumer

- (BCOVAMCSessionConsumer *)videoHeartbeatSessionConsumer
{
    BCOVAMCVideoHeartbeatConfigurationPolicy videoHeartbeatConfigurationPolicy = ^ADBMediaHeartbeatConfig *(id<BCOVPlaybackSession> session) {
        
        ADBMediaHeartbeatConfig *configData = [[ADBMediaHeartbeatConfig alloc] init];
        
        configData.trackingServer = @"ovppartners.hb.omtrdc.net";
        configData.channel = @"test-channel";
        configData.appVersion = @"1.0.0";
        configData.ovp = @"Brightcove";
        configData.playerName = @"BasicOmniturePlayer";
        configData.ssl = NO;
        
        // NOTE: remove this in production code.
        configData.debugLogging = YES;
        
        return configData;
    };
    
    BCOVAMCAnalyticsPolicy *heartbeatPolicy = [[BCOVAMCAnalyticsPolicy alloc] initWithHeartbeatConfigurationPolicy:videoHeartbeatConfigurationPolicy];
    
    return [BCOVAMCSessionConsumer heartbeatAnalyticsConsumerWithPolicy:heartbeatPolicy delegate:self];
}

- (BCOVAMCSessionConsumer *)mediaAnalyticsSessionConsumer
{
    BCOVAMCMediaSettingPolicy mediaSettingPolicy = ^ADBMediaSettings *(id<BCOVPlaybackSession> session) {
        ADBMediaSettings *settings = [ADBMobile mediaCreateSettingsWithName:@"BCOVOmniturePlayerMediaSettings"
        // You can set video length to 0. Omniture plugin will update it later for you.
                                                                     length:0
                                                                 playerName:@"BasicOmniturePlayer"
                                                                   playerID:@"BasicOmniturePlayer"];
        // Adobe media analytics setting customization
        // settings.milestones = @"25,50,75";
        
        return settings;
    };
    
    BCOVAMCAnalyticsPolicy *mediaPolicy = [[BCOVAMCAnalyticsPolicy alloc] initWithMediaSettingsPolicy:mediaSettingPolicy];
    
    return [BCOVAMCSessionConsumer mediaAnalyticsConsumerWithPolicy:mediaPolicy delegate:self];
}


#pragma mark view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self UISetup];
    
}

- (void)UISetup
{
    // Create and configure Control View.
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:nil controlsView:controlView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.videoContainerView addSubview:self.playerView];
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
                                              [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
                                              [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
                                              [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
                                            ]];
    
    [self requestContentFromPlaybackService];
}


- (void)requestContentFromPlaybackService
{
	[self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        if (video)
        {
            [self.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }
        
    }];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}


#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - BCOVAMCSessionConsumerHeartbeatDelegate

- (void)heartbeatVideoUnloadedOnSession:(id<BCOVPlaybackSession>)session;
{
    NSLog(@"ViewController Debug - heartbeatVideoUnloadedOnSession:");
}

#pragma mark - @protocol BCOVAMCSessionConsumerMediaDelegate <NSObject>

- (void)mediaOnSession:(id<BCOVPlaybackSession>)session mediaState:(ADBMediaState *)mediaState;
{
    NSLog(@"mediaEvent = %@", mediaState.mediaEvent);
    if([mediaState.mediaEvent isEqualToString:@"MILESTONE"])
    {
        NSLog(@"milestone = %lu", (unsigned long)mediaState.milestone);
    }
}


@end
