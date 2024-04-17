//
//  ViewController.m
//  BasicPulsePlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <Pulse/Pulse.h>
#import <BrightcovePulse/BrightcovePulse.h>

#import "BCOVPulseVideoItem.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";

// Replace with your own Pulse Host info
static NSString * const kPulseHost = @"https://bc-test.videoplaza.tv";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVPulsePlaybackSessionDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIView *companionSlotContainerView;
@property (nonatomic, weak) IBOutlet UIView *headerTableView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UILabel *headerLabel;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackSessionProvider> pulseSessionProvider;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) NSArray *videoItems;
@property (nonatomic, strong) BCOVPulseVideoItem *videoItem;
@property (nonatomic, strong) BCOVVideo *video;

@property (nonatomic, assign) BOOL statusBarHidden;

@end


@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setup];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(requestTrackingAuthorization)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setup
{
    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];

        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });

    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        options.presentingViewController = self;
        options.automaticControlTypeSelection = YES;

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:nil];

        playerView.delegate = self;

        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];

        playerView;
    });

    self.pulseSessionProvider = ({
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

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
        OOContentMetadata *contentMetadata = [OOContentMetadata new];

        // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
        OORequestSettings *requestSettings = [OORequestSettings new];

        BCOVPulseCompanionSlot *companionSlot = [[BCOVPulseCompanionSlot alloc] initWithView:self.companionSlotContainerView
                                                                                       width:400
                                                                                      height:100];

        NSString *persistentId = ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;

        NSDictionary *pulsePlaybackSessionOptions = @{ kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
                                                       kBCOVPulseOptionPulsePersistentIdKey: persistentId };

        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        [sdkManager createPulseSessionProviderWithPulseHost:kPulseHost
                                            contentMetadata:contentMetadata
                                            requestSettings:requestSettings
                                                adContainer:self.playerView.contentOverlayView
                                             companionSlots:@[companionSlot]
                                    upstreamSessionProvider:fps
                                                    options:pulsePlaybackSessionOptions];
    });

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:self.pulseSessionProvider
                                                         viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });

    self.headerLabel = ({
        CGSize size = self.headerTableView.frame.size;
        CGRect frame = CGRectMake(20, 0, size.width - 40, size.height);
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.text = @"Basic Pulse Player";
        headerLabel.numberOfLines = 1;
        headerLabel.textAlignment = NSTextAlignmentJustified;
        headerLabel.font = [UIFont systemFontOfSize:16];
        headerLabel.textColor = UIColor.systemGrayColor;
        headerLabel.backgroundColor = UIColor.clearColor;
        headerLabel;
    });

    self.headerTableView.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1.0].CGColor;
    self.headerTableView.layer.borderWidth = 0.3f;
    [self.headerTableView addSubview:self.headerLabel];

    self.videoItems = ({
        // Load video library from Library.json into a JSON array.
        NSMutableArray *videoItems = @[].mutableCopy;

        NSString *path = [NSBundle.mainBundle pathForResource:@"Library"
                                                       ofType:@"json"];
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        NSArray *jsonResult = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingMutableLeaves
                                                                error:nil];
        for (NSDictionary *element in jsonResult)
        {
            BCOVPulseVideoItem *item = [BCOVPulseVideoItem initWithDictionary:element];
            [videoItems addObject:item];
        }

        videoItems.copy;
    });
}

- (void)requestTrackingAuthorization
{
    if (@available(iOS 14.5, *))
    {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            switch (status)
            {
                case ATTrackingManagerAuthorizationStatusAuthorized:
                    NSLog(@"Authorized Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusDenied:
                    NSLog(@"Denied Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusNotDetermined:
                    NSLog(@"Not Determined Tracking Permission");
                    break;
                case ATTrackingManagerAuthorizationStatusRestricted:
                    NSLog(@"Restricted Tracking Permission");
                    break;
            }

            NSLog(@"IDFA: %@", ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString);

            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed.
                // Start loading ads here.
                [self requestContentFromPlaybackService];
            });

        }];
    }
    else
    {
        [self requestContentFromPlaybackService];
    }

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ kBCOVPlaybackServiceConfigurationKeyAssetID: kVideoId };
    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:nil
                                          completion:^(BCOVVideo *video,
                                                       NSDictionary *jsonResponse,
                                                       NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (video)
        {
            strongSelf.video = video;
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }
    }];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
  didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventFail isEqualToString:lifecycleEvent.eventType])
    {
        NSError *error = lifecycleEvent.properties[@"error"];
        // Report any errors that may have occurred with playback.
        NSLog(@"ViewController - Playback error: %@", error.localizedDescription);
    }
}


#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
        didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController - Entering ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
         didExitAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController - Exiting ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
                didEnterAd:(BCOVAd *)ad
{
    NSLog(@"ViewController - Entering ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller
           playbackSession:(id<BCOVPlaybackSession>)session
                 didExitAd:(BCOVAd *)ad
{
    NSLog(@"ViewController - Exiting ad");
}


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}


#pragma mark BCOVPulsePlaybackSessionDelegate

- (id<OOPulseSession>)createSessionForVideo:(BCOVVideo *)video
                              withPulseHost:(NSString *)pulseHost
                            contentMetadata:(OOContentMetadata *)contentMetadata
                            requestSettings:(OORequestSettings *)requestSettings
{
    // Override the content metadata.
    contentMetadata.category = self.videoItem.category;
    contentMetadata.tags = self.videoItem.tags;

    // Override the request settings.
    requestSettings.linearPlaybackPositions = self.videoItem.midrollPositions;

    return [OOPulse sessionWithContentMetadata:contentMetadata
                               requestSettings:requestSettings];
}


#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.videoItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:@"VideoTableViewCell"
                                                                 forIndexPath:indexPath];

    BCOVPulseVideoItem *item = self.videoItems[indexPath.item];

    videoCell.textLabel.text = item.title ?: @"";
    videoCell.textLabel.textColor = UIColor.blackColor;

    videoCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",
                                      item.category ?: @"",
                                      [item.tags componentsJoinedByString:@", "] ?: @""];
    videoCell.detailTextLabel.textColor = UIColor.grayColor;

    return videoCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if TARGET_OS_SIMULATOR
    if (self.video.usesFairPlay)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FairPlay Warning"
                                                                       message:@"FairPlay only works on actual iOS or tvOS devices.\n\nYou will not be able to view any FairPlay content in the iOS or tvOS simulator."
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });

        return;
    }
#endif

    self.videoItem = self.videoItems[indexPath.item];

    [self.playbackController setVideos:@[ self.video ]];

    if (self.videoItem.extendSession)
    {
        // Delay execution.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
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
            extendRequestSettings.linearPlaybackPositions = @[ @(30) ];
            extendRequestSettings.insertionPointFilter = OOInsertionPointTypePlaybackPosition;

            [(BCOVPulseSessionProvider *)self.pulseSessionProvider
             requestSessionExtensionWithContentMetadata:extendContentMetadata
             requestSettings:extendRequestSettings success:^{

                NSLog(@"Session was successfully extended. There are now midroll ads at 30th second.");
            }];
        });
    }
}

@end
