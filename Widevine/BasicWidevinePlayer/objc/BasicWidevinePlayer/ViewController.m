//
//  ViewController.m
//  BasicWidevinePlayer
//
//  Created by Mike Moscardini on 2/26/15.
//  Copyright (c) 2015 Brightcove. All rights reserved.
//

#import "ViewController.h"

#import <BCOVPlayerSDK.h>
#import <BCOVWidevine.h>

// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"FqicLlYykdimMML7pj65Gi8IHl8EVReWMJh6rLDcTjTMqdb5ay_xFA..";
static NSString * const kViewControllerPlaylistReferenceID = @"ios_videos";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) id<BCOVPlaybackSession> currentSession;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setup];

    self.playbackController.view.frame = self.videoContainer.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer insertSubview:self.playbackController.view atIndex:0];

    [self requestContentFromCatalog];
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    // Create the Widevine session provider.
    id<BCOVPlaybackSessionProvider> widevineSessionProvider = [manager createWidevineSessionProviderWithOptions:[[BCOVWidevineSessionProviderOptions alloc] init]];

    // Creating a Widevine session provider based on the above code will initialize a
    // Widevine component using it's default settings. These settings and defaults
    // are explained in BCOVWidevineSessionProvider.h.
    // If you want to change these settings, you can initialize the plugin like so:
    //
    // BCOVWidevineSessionProviderOptions *options = [[BCOVWidevineSessionProviderOptions alloc] init];
    // options.widevineSettings = @{ WVPlayerDrivenAdaptationKey: @0 };
    // id<BCOVPlaybackSessionProvider> sessionProvider = [manager createWidevineSessionProviderWithOptions:options];

    self.playbackController = [manager createPlaybackControllerWithSessionProvider:widevineSessionProvider viewStrategy:[manager defaultControlsViewStrategy]];
    self.playbackController.delegate = self;
    self.playbackController.autoAdvance = YES;
    self.playbackController.autoPlay = YES;

    self.catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)requestContentFromCatalog
{
    [self.catalogService findWidevinePlaylistWithReferenceID:kViewControllerPlaylistReferenceID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {

        if (playlist)
        {
            [self.playbackController setVideos:playlist.videos];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving playlist: %@", error);
        }
        
    }];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
    self.currentSession = session;
}

-(void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Widevine and Ad events are emitted though lifecycle events. The events
    // are defined in BCOVWidevineComponent.h.

    NSString *type = lifecycleEvent.eventType;

    if ([type isEqualToString:kBCOVWidevineLifecycleEventWViOsApi])
    {
        NSLog(@"ViewController Debug - Widevine Event: `%@`", lifecycleEvent.properties);
    }
    else
    {
        NSLog(@"ViewController Debug - `%@` Event: `%@`", lifecycleEvent.eventType, lifecycleEvent.properties);
    }
}

#pragma mark Logging

- (IBAction)handlePrintLogButton:(id)sender
{
    AVPlayerItemAccessLog *accessLog = self.currentSession.player.currentItem.accessLog;
    NSString *accessLogStr = [[NSString alloc] initWithData:[accessLog extendedLogData] encoding:[accessLog extendedLogDataStringEncoding]];

    AVPlayerItemErrorLog *errorLog = self.currentSession.player.currentItem.errorLog;
    NSString *errorLogStr = [[NSString alloc] initWithData:[errorLog extendedLogData] encoding:[errorLog extendedLogDataStringEncoding]];

    NSLog(@"");
    NSLog(@"ViewController Debug - Logging");
    NSLog(@"");
    NSLog(@"Access Log");
    NSLog(@"%@", accessLogStr);
    NSLog(@"");
    NSLog(@"Error Log");
    NSLog(@"%@", errorLogStr);
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
