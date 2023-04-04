//
//  ViewController.m
//  FairPlayPulsePlayer
//
//  Created by Carlos Ceja on 2/7/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

@import AppTrackingTransparency;

@import Pulse;

@import BrightcovePlayerSDK;
@import BrightcovePulse;

#import "ViewController.h"


static NSString * const kServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kAccountID = @"5434391461001";
static NSString * const kVideoID = @"6140448705001";

// Replace with your own Pulse Host info:
static NSString * const kPulseHost = @"https://bc-test.videoplaza.tv";


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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 14, *))
    {
        __weak typeof(self) weakSelf = self;
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed. Start loading ads here.
                [strongSelf videoLibrary];
                [strongSelf setupPlayerView];
                [strongSelf setupPlaybackController];
            });
        }];
    }
    else
    {
        [self videoLibrary];
        [self setupPlayerView];
        [self setupPlaybackController];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // FairPlay doesn't work when we're running in a simulator, so put up an alert.
#if TARGET_OS_SIMULATOR
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FairPlay Warning"
                                                                   message:@"FairPlay only works on actual iOS devices, not in a simulator.\n\nYou will not be able to view any FairPlay content."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault  handler:^(UIAlertAction *action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
#endif
}


#pragma mark Misc

- (void)requestVideo
{
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kServicePolicyKey];
    
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *configuration = @{kBCOVPlaybackServiceConfigurationKeyAssetID:kVideoID};
    [playbackService findVideoWithConfiguration:configuration queryParameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            weakSelf.video = video;
            
            [weakSelf.tableView reloadData];
        }
        else
        {
             NSLog(@"ViewController Debug - Error retrieving video");
        }
        
    }];
}

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = BCOVPlayerSDKManager.sharedManager;
    
    // Create an authorization proxy for FairPlay
    // using the FairPlay Application ID and the FairPlay Publisher ID
   BCOVFPSBrightcoveAuthProxy *proxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                  applicationId:nil];
    
    id<BCOVPlaybackSessionProvider> fps = [manager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                        authorizationProxy:proxy
                                                                                   upstreamSessionProvider:nil];

    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
    OOContentMetadata *contentMetadata = [OOContentMetadata new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
    OORequestSettings *requestSettings = [OORequestSettings new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Enums/OOSeekMode.html
    
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
    
    // Create a companion slot.
    BCOVPulseCompanionSlot *companionSlot = [[BCOVPulseCompanionSlot alloc] initWithView:self.companionSlotContainerView width:400 height:100];
    
    self.pulseSessionProvider = [manager createPulseSessionProviderWithPulseHost:kPulseHost
                                                                     contentMetadata:contentMetadata
                                                                     requestSettings:requestSettings
                                                                         adContainer:self.playerView.contentOverlayView
                                                                      companionSlots:@[companionSlot]
                                                             upstreamSessionProvider:fps
                                                                             options:pulseProperties];
    
    NSLog(@"Creating playback controller");
    
    self.playbackController = [manager createPlaybackControllerWithSessionProvider:self.pulseSessionProvider
                                                                          viewStrategy:nil];
    
    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    self.playbackController.delegate = self;
    
    self.playerView.playbackController = self.playbackController;
    
    [self requestVideo];
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
    
    if ([kBCOVPlaybackSessionLifecycleEventAdEnter isEqualToString:lifecycleEvent.eventType])
    {
        [self.playbackController pauseAd];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.playbackController resumeAd];
            
        });
    }
}


#pragma mark BCOVPulsePlaybackSessionDelegate

- (id<OOPulseSession>)createSessionForVideo:(BCOVVideo *)video withPulseHost:(NSString *)pulseHost contentMetadata:(OOContentMetadata *)contentMetadata requestSettings:(OORequestSettings *)requestSettings
{
    if (!pulseHost)
    {
        return nil;
    }
    
     // Override the content metadata.
    contentMetadata.category = self.videoItem.category;
    contentMetadata.tags     = self.videoItem.tags;
    
    // Override the request settings.
    requestSettings.linearPlaybackPositions = self.videoItem.midrollPositions;
    //requestSettings
    
    return [OOPulse sessionWithContentMetadata:contentMetadata requestSettings:requestSettings];
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.videoContainer.hidden = NO;
    
    self.videoItem = self.videoItems[indexPath.item];
        
    [self.playbackController setVideos:@[ self.video ]];

    if (self.videoItem.extendSession)
    {
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

            [(BCOVPulseSessionProvider *)self.pulseSessionProvider requestSessionExtensionWithContentMetadata:extendContentMetadata requestSettings:extendRequestSettings success:^{

                NSLog(@"Session was successfully extended. There are now midroll ads at 30th second.");

            }];
        });
    }
}


#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.video ? self.videoItems.count : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"FairPlay Pulse Player";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    
    BCOVPulseVideoItem *item = self.videoItems[indexPath.item];
    
    cell.textLabel.text = item.title ?: @"";
    cell.textLabel.textColor = UIColor.blackColor;
    
    NSString *subtitle = item.category ?: @"";
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", subtitle, [item.tags componentsJoinedByString:@", "] ?: @""];
    cell.detailTextLabel.textColor = UIColor.grayColor;
    
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
    
    videoItem.title            = dictionary[@"content-title"];
    videoItem.category         = dictionary[@"category"];
    videoItem.tags             = dictionary[@"tags"];
    videoItem.midrollPositions = dictionary[@"midroll-positions"];
    videoItem.extendSession    = dictionary[@"extend-session"];
    
    return videoItem;
}

@end
