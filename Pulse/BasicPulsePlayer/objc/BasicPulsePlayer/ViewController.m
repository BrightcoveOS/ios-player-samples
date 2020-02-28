//
//  ViewController.m
//  BasicPulsePlayer
//
//  Created by Carlos Ceja on 2/7/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

@import Pulse;
@import BrightcovePlayerSDK;
@import BrightcovePulse;

#import "ViewController.h"

static NSString * const kServicePolicyKey = @"insertyourservicepolicykeyhere";
static NSString * const kAccountID = @"insertyouraccountidhere";
static NSString * const kVideoID = @"insertyourvideoidhere";

// Replace with your own Pulse Host info:
static NSString * const kPulseHost = @"insertyourpulsehosthere";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPulsePlaybackSessionDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (nonatomic, weak) IBOutlet UIView *companionSlotContainerView;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) id<BCOVPlaybackSessionProvider> pulseSessionProvider;

@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVVideo *video;

@property (nonatomic, strong) NSArray <BCOVPulseVideoItem *> *videoItems;
@property (nonatomic, strong) BCOVPulseVideoItem *videoItem;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self videoLibrary];
    
    [self setupPlayerView];
    [self setupPlaybackController];
    [self requestVideo];
}

#pragma mark Misc

- (void)requestVideo
{
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kServicePolicyKey];
    
    __weak typeof(self) weakSelf = self;
    
    [playbackService findVideoWithVideoID:kVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            weakSelf.video = video;
            
            [weakSelf.tableView reloadData];
        }
        else
        {
             NSLog(@"PlayerViewController Debug - Error retrieving video");
        }
        
    }];
}

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = BCOVPlayerSDKManager.sharedManager;

    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
    OOContentMetadata *contentMetadata = [OOContentMetadata new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
    OORequestSettings *requestSettings = [OORequestSettings new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Enums/OOSeekMode.html
    requestSettings.seekMode = 3; // PLAY_ALL_ADS;
    
    NSDictionary *pulseProperties = @{ kBCOVPulseOptionPulsePlaybackSessionDelegateKey:self };
    
    // Create a companion slot.
    BCOVPulseCompanionSlot *companionSlot = [[BCOVPulseCompanionSlot alloc] initWithView:self.companionSlotContainerView width:400 height:100];
        
    self.pulseSessionProvider = [manager createPulseSessionProviderWithPulseHost:kPulseHost
                                                                 contentMetadata:contentMetadata
                                                                 requestSettings:requestSettings
                                                                     adContainer:self.playerView.contentOverlayView
                                                                  companionSlots:@[companionSlot]
                                                         upstreamSessionProvider:nil
                                                                         options:pulseProperties];
    
    self.playbackController = [manager createPlaybackControllerWithSessionProvider:self.pulseSessionProvider
                                                                      viewStrategy:nil];

    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    self.playbackController.delegate = self;
    
    self.playerView.playbackController = self.playbackController;
}

- (void)setupPlayerView
{
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;
    
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:controlView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.videoContainer addSubview:self.playerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
        [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
        [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
        [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
    ]];
}

// Load video library from Library.json into a JSON array.
- (NSArray<NSDictionary *> *)jsonVideoObjects
{
    NSError *jsonError;
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"Library" ofType:@"json"];
    NSArray<NSDictionary *> *jsonObjects = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfFile:path] options:0 error:&jsonError];
    
    assert(jsonError == nil);
    return jsonObjects;
}

- (void)videoLibrary
{
    if (!self.videoItems)
    {
        // Parse and add each video in the JSON array to our video library
        NSMutableArray *videos = [NSMutableArray array];
        
        for (NSDictionary *jsonObject in [self jsonVideoObjects])
        {
            [videos addObject:[BCOVPulseVideoItem initWithDictionary:jsonObject]];
        }
        
        self.videoItems = [NSArray arrayWithArray:videos];
    }
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

- (id<OOPulseSession>)createSessionForVideo:(BCOVVideo *)video withPulseHost:(NSString *)pulseHost contentMetdata:(OOContentMetadata *)contentMetadata requestSettings:(OORequestSettings *)requestSettings
{
    if (!pulseHost)
    {
        return nil;
    }
    
     // Override the content metadata.
    contentMetadata.category = self.videoItem.category;
    contentMetadata.tags     = self.videoItem.tags;
    contentMetadata.flags    = self.videoItem.flags;
    
    // Override the request settings.
    requestSettings.linearPlaybackPositions = self.videoItem.midrollPositions;
    
    return [OOPulse sessionWithContentMetadata:contentMetadata requestSettings:requestSettings];
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.videoContainer.hidden = NO;
    
    self.videoItem = self.videoItems[indexPath.item];
        
    [self.playbackController setVideos:@[ self.video ]];
}


#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.video ? self.videoItems.count : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Basic Pulse Player";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    
    BCOVPulseVideoItem *item = self.videoItems[indexPath.item];
    
    cell.textLabel.text = item.title ?: @"";
    
    NSString *subtitle = item.category ?: @"";
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", subtitle, [item.tags componentsJoinedByString:@", "] ?: @""];
    
    return cell;
}


#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end


#pragma mark - BCOVPulseVideoItem

@implementation BCOVPulseVideoItem

+ (BCOVPulseVideoItem *)initWithDictionary:(NSDictionary *)dictionary
{
    BCOVPulseVideoItem *videoItem = [BCOVPulseVideoItem new];
    
    videoItem.title            = dictionary[@"content-title"] ?: @"";
    videoItem.category         = dictionary[@"category"];
    videoItem.tags             = dictionary[@"tags"];
    videoItem.flags            = dictionary[@"flags"];
    videoItem.midrollPositions = dictionary[@"midroll-positions"];
    
    return videoItem;
}

@end
