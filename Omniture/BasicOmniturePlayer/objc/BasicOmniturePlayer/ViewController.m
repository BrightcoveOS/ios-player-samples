//
//  ViewController.m
//  BasicOmniturePlayer
//
//  Copyright (c) 2014 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

#import "BCOVPlayerSDK.h"

#import "BCOVAMC.h"

@import MediaPlayer;

// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVAMCSessionConsumerHeartbeatDelegate, BCOVAMCSessionConsumerMeidaDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

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
    
    _playbackController = [manager createPlaybackControllerWithViewStrategy:[manager defaultControlsViewStrategy]];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = NO;

    // Use Adobe Video Haartbeat analytics
    [_playbackController addSessionConsumer: [self videoHeartbeatSessionConsumer]];
    // or Use Adobe media analytics
    //[_playbackController addSessionConsumer: [self mediaAnalyticsSessionConsumer]];

    
    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
    
}


#pragma mark BCOVAMCSessionConsumer

- (BCOVAMCSessionConsumer *)mediaAnalyticsSessionConsumer
{
    BCOVAMCMediaSettingPolicy mediaSettingPolicy = ^ADBMediaSettings *(id<BCOVPlaybackSession> session) {
        ADBMediaSettings *settings = [ADBMobile mediaCreateSettingsWithName:@"BasicOmniturePlayerMeidaSettings"
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

- (BCOVAMCSessionConsumer *)videoHeartbeatSessionConsumer
{
    BCOVAMCVideoHeartbeatConfigurationPolicy videoHeartbeatConfigurationPolicy = ^ADB_VHB_ConfigData *(id<BCOVPlaybackSession> session) {
        
        ADB_VHB_ConfigData *configuData = [[ADB_VHB_ConfigData alloc] initWithTrackingServer:@"sample-server" jobId:@"sample-job" publisher:@"sample-publisher"];
        configuData.channel = @"test_channel";
        
        // Set this to true to activate the debug tracing.
        // NOTE: remove this in production code.
        configuData.debugLogging = YES;
        return configuData;
    };
    
    BCOVAMCVideoHeartbeatVideoInfoPolicy videoHeartbeatVideoInfoPolicy = ^ADB_VHB_VideoInfo *(id<BCOVPlaybackSession> session) {
        
        ADB_VHB_VideoInfo *videoInfo = [[ADB_VHB_VideoInfo alloc] init];
        // Use session.video.properties[<key>] as videoID
        NSString *videoID = session.video.properties[kBCOVCatalogJSONKeyId];
        videoInfo.id = videoID;
        videoInfo.name = videoID;
        videoInfo.playerName = @"BasicOmniturePlayer";
        return videoInfo;
        
    };
    
    BCOVAMCAnalyticsPolicy *heartbeatPolicy = [[BCOVAMCAnalyticsPolicy alloc] initWithHeartbeatConfigurationPolicy: videoHeartbeatConfigurationPolicy videoInfoPolicy: videoHeartbeatVideoInfoPolicy];
    
    return [BCOVAMCSessionConsumer heartbeatAnalyticsConsumerWithPolicy:heartbeatPolicy delegate:self];
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
    self.playbackController.view.frame = self.videoContainerView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainerView addSubview:self.playbackController.view];
    
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
- (void)heartbeatOnSession:(id<BCOVPlaybackSession>)session error:(ADB_VHB_ErrorInfo *)errorInfo;
{
    NSLog(@"error = %@ %@", errorInfo.message, errorInfo.details);
}
- (void)heartbeatVideoUnloadedOnSession:(id<BCOVPlaybackSession>)session;
{
    
}

#pragma mark - @protocol BCOVAMCSessionConsumerMeidaDelegate <NSObject>

- (void)mediaOnSession:(id<BCOVPlaybackSession>)session mediaState:(ADBMediaState *)mediaState;
{
    NSLog(@"mediaEvent = %@", mediaState.mediaEvent);
    if([mediaState.mediaEvent isEqualToString:@"MILESTONE"])
    {
        NSLog(@"milestone = %lu", (unsigned long)mediaState.milestone);
    }
}


@end
