//
//  ViewController.m
//  BrightcoveCastReceiver
//
//  Created by Jeremy Blaker on 7/6/20.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"

@import GoogleCast;
@import BrightcovePlayerSDK;
@import BrightcoveGoogleCast;

static NSString * const kServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kAccountID = @"5434391461001";
static NSString * const kPlaylistRefID = @"brightcove-native-sdk-plist";

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, BCOVGoogleCastManagerDelegate, BCOVPlaybackControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVPlaylist *playlist;
@property (nonatomic, strong) BCOVGoogleCastManager *googleCastManager;

@end

@implementation ViewController

#pragma mark - View Lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.videoContainer.hidden = YES;
    
    GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:castButton];

    BCOVReceiverAppConfig *receiverAppConfig = [BCOVReceiverAppConfig new];
    receiverAppConfig.accountId = kAccountID;
    receiverAppConfig.policyKey = kServicePolicyKey;
    
    // You can use the authToken property for PAS/EPA
    //receiverAppConfig.authToken = @"";
    
    // You can use the adConfigId property for SSAI
    //receiverAppConfig.adConfigId = @"";
    
    self.googleCastManager = [[BCOVGoogleCastManager alloc] initForBrightcoveReceiverApp:receiverAppConfig];
    self.googleCastManager.delegate = self;

    [self setupPlaybackController];
    [self setupPlayerView];
    [self requestPlaylist];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(castDeviceDidChange:)
                                                 name:kGCKCastStateDidChangeNotification
                                               object:[GCKCastContext sharedInstance]];
}

#pragma mark - Misc

- (void)castDeviceDidChange:(NSNotification *)notification
{
    switch ([GCKCastContext sharedInstance].castState) {
        case GCKCastStateNoDevicesAvailable:
            NSLog(@"Cast Status: No Devices Available");
            break;
        case GCKCastStateNotConnected:
            NSLog(@"Cast Status: Not Connected");
            break;
        case GCKCastStateConnecting:
            NSLog(@"Cast Status: Connecting");
            break;
        case GCKCastStateConnected:
            NSLog(@"Cast Status: Connected");
            break;
    }
}

- (void)requestPlaylist
{
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kServicePolicyKey];
    
    __weak typeof(self) weakSelf = self;
    [playbackService findPlaylistWithReferenceID:kPlaylistRefID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
       
        if (playlist)
        {
            weakSelf.playlist = playlist;
            [weakSelf.tableView reloadData];
        }
        else
        {
            NSLog(@"PlayerViewController Debug - Error retrieving video playlist");
        }
        
    }];
}

- (void)setupPlaybackController
{
    self.playbackController = [BCOVPlayerSDKManager.sharedManager createPlaybackController];
    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    self.playbackController.delegate = self;
    
    [self.playbackController addSessionConsumer:self.googleCastManager];
}

- (void)setupPlayerView
{
    BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
    options.presentingViewController = self;
    
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:controlView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.videoContainer addSubview:self.playerView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                              [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                              [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                              [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                              ]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.playlist ? 2 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : self.playlist.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"Play All";
    }
    
    if (indexPath.section == 1)
    {
        BCOVVideo *video = self.playlist.videos[indexPath.row];
        cell.textLabel.text = video.properties[kBCOVVideoPropertyKeyName];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? self.playlist.properties[kBCOVPlaylistPropertiesKeyName] : nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.videoContainer.hidden = [GCKCastContext sharedInstance].castState == GCKCastStateConnected;
    
    if (indexPath.section == 0)
    {
        [self.playbackController setVideos:self.playlist.videos];
        return;
    }
    
    BCOVVideo *video = self.playlist.videos[indexPath.row];
    
    [self.playbackController setVideos:@[video]];
}

#pragma mark - BCOVGoogleCastManagerDelegate

- (void)switchedToRemotePlayback
{
    self.videoContainer.hidden = YES;
}

- (void)switchedToLocalPlayback:(NSTimeInterval)lastKnownStreamPosition withError:(NSError *)error
{
    if (lastKnownStreamPosition > 0)
    {
        [self.playbackController play];
    }
    self.videoContainer.hidden = NO;
    
    if (error)
    {
        NSLog(@"Switched to local playback with error: %@", error.localizedDescription);
    }
}

- (void)currentCastedVideoDidComplete
{
    self.videoContainer.hidden = YES;
}

- (void)suitableSourceNotFound
{
    NSLog(@"Suitable source for video not found!");
}

- (void)castedVideoFailedToPlay
{
    NSLog(@"Casted video failed to play!");
}

#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventEnd])
    {
        self.videoContainer.hidden = YES;
    }
}
@end
