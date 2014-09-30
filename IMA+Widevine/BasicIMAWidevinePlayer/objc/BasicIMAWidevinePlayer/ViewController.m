//
//  ViewController.m
//  BasicIMAWidevinePlayer
//
//  Created by Mike Moscardini on 10/27/14.
//  Copyright (c) 2014 BrightCove. All rights reserved.
//

#import <BCOVIMA.h>
#import <BCOVWidevine.h>

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"FqicLlYykdimMML7pj65Gi8IHl8EVReWMJh6rLDcTjTMqdb5ay_xFA..";
static NSString * const kViewControllerPlaylistReferenceID = @"ios_videos";

static NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
static NSString * const kViewControllerIMALanguage = @"en";
static NSString * const kViewControllerIMAVMAPResponseAdTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, assign) BOOL isBrowserOpen;
@property (nonatomic, strong) id<NSObject> notificationReceipt;

@end


@implementation ViewController

#pragma mark Setup Methods

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_notificationReceipt];
}

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

    // In order to use Widevine and IMA together, we are going to compose a
    // Widevine session provider and a IMA session provider together. We will
    // create a pipeline that starts with the Widevine provider and ends with the
    // IMA provider.

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

    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;

    // Create an IMA session provider. We pass the Widevine session provider
    // as the upstream session provider, thus creating our pipeline.
    // When using IMA and Widevine together, Widevine *must* be placed first.
    id<BCOVPlaybackSessionProvider> imaSessionProvider = [manager createIMASessionProviderWithSettings:imaSettings adsRenderingSettings:renderSettings upstreamSessionProvider:widevineSessionProvider options:[BCOVIMASessionProviderOptions VMAPOptions]];

    _playbackController = [manager createPlaybackControllerWithSessionProvider:imaSessionProvider viewStrategy:[manager IMAAdViewStrategyWrapperWithViewStrategey:[manager defaultControlsViewStrategy]]];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];

    [self resumeAdAfterForeground];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.playbackController.view.frame = self.videoContainer.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer addSubview:self.playbackController.view];

    [self requestContentFromCatalog];
}

- (void)resumeAdAfterForeground
{
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.

    ViewController * __weak weakSelf = self;

    self.notificationReceipt = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {

        ViewController *strongSelf = weakSelf;

        if (strongSelf.adIsPlaying && !strongSelf.isBrowserOpen)
        {
            [strongSelf.playbackController resumeAd];
        }

    }];
}

- (void)requestContentFromCatalog
{
    // In order to play back content, we are going to request a playlist from the
    // catalog service. The Widevine component offers methods for retrieving Widevine
    // Content. The data in the catalog does not have the required
    // VMAP tag on the video, so this code demonstrates how to update a playlist
    // to set the ad tags on the video.
    // You are responsible for determining where the ad tag should originate from.
    // We advise that if you choose to hard code it into your app, that you provide
    // a mechanism to update it without having to submit an update to your app.

    [self.catalogService findWidevinePlaylistWithReferenceID:kViewControllerPlaylistReferenceID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {

        if (playlist)
        {
            BCOVPlaylist *updatedPlaylist = [playlist update:^(id<BCOVMutablePlaylist> mutablePlaylist) {

                NSMutableArray *updatedVideos = [NSMutableArray arrayWithCapacity:mutablePlaylist.videos.count];

                for (BCOVVideo *video in mutablePlaylist.videos)
                {
                    [updatedVideos addObject:[ViewController updateVideoWithVMAPTag:video]];
                }

                mutablePlaylist.videos = updatedVideos;

            }];

            [self.playbackController setVideos:updatedPlaylist.videos];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving playlist: %@", error);
        }

    }];
}

+ (BCOVVideo *)updateVideoWithVMAPTag:(BCOVVideo *)video
{
    // Update each video to add the tag.
    return [video update:^(id<BCOVMutableVideo> mutableVideo) {

        // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
        // the video's properties when using server side ad rules. This URL returns
        // a VMAP response that is handled by the Google IMA library.
        NSDictionary *adProperties = @{ kBCOVIMAAdTag : kViewControllerIMAVMAPResponseAdTag };

        NSMutableDictionary *propertiesToUpdate = [mutableVideo.properties mutableCopy];
        [propertiesToUpdate addEntriesFromDictionary:adProperties];
        mutableVideo.properties = propertiesToUpdate;

    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

-(void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Widevine and Ad events are emitted though lifecycle events. The events
    // are defined in BCOVWidevineComponent.h and BCOVIMAComponent.h respectively.

    NSString *type = lifecycleEvent.eventType;

    if ([type isEqualToString:kBCOVIMALifecycleEventAdsLoaderLoaded])
    {
        NSLog(@"ViewController Debug - Ads loaded.");
    }
    else if ([type isEqualToString:kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];

        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                NSLog(@"ViewController Debug - Ad Started.");
                self.adIsPlaying = YES;
                break;
            case kIMAAdEvent_COMPLETE:
                NSLog(@"ViewController Debug - Ad Completed.");
                self.adIsPlaying = NO;
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController Debug - All ads completed.");
                break;
            default:
                break;
        }
    }
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

