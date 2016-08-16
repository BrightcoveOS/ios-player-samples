//
//  ViewController.m
//  BCOVOmniturePlayer
//
//  Copyright (c) 2014 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

// Adobe Media Heartbeat
#import "ADBMediaHeartbeat.h"
#import "ADBMediaHeartbeatConfig.h"

// Adobe Mobile Marketing Cloud
#import "ADBMobile.h"

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVAMCSessionConsumerHeartbeatDelegate, BCOVAMCSessionConsumerMeidaDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
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

    
    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
    
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
        ADBMediaSettings *settings = [ADBMobile mediaCreateSettingsWithName:@"BCOVOmniturePlayerMeidaSettings"
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
    self.playerView.frame = self.videoContainerView.bounds;
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.videoContainerView addSubview:self.playerView];
    
    [self requestContentFromCatalog];
}


- (void)requestContentFromCatalog
{
    [self.catalogService findPlaylistWithPlaylistID:kViewControllerPlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        if (playlist)
        {
            [self.playbackController setVideos:playlist.videos];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving playlist: `%@`", error);
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
    // FIXME: does this get called?
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
