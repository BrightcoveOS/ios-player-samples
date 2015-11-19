//
//  ViewController.m
//  BasicIMAPlayer
//
//  Copyright (c) 2014 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

@import GoogleInteractiveMediaAds;

@import BrightcovePlayerSDK;
@import BrightcoveIMA;


#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";

static NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
static NSString * const kViewControllerIMALanguage = @"en";
static NSString * const kViewControllerIMAVMAPResponseAdTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";


@interface ViewController () <BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setup];
    
    self.playbackController.view.frame = self.videoContainer.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Make sure the content view won't cover the any subviews (ad view) in ad container view.
    [self.videoContainer addSubview:self.playbackController.view];
    
    [self requestContentFromCatalog];
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    // BCOVIMAAdsRequestPolicy provides methods to specify VAST or VMAP/Server Side Ad Rules. Select the appropriate method to select your ads policy.
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy videoPropertiesVMAPAdTagUrlAdsRequestPolicy];
    
    self.playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings adsRenderingSettings:renderSettings adsRequestPolicy:adsRequestPolicy adContainer:self.videoContainer companionSlots:nil viewStrategy:[manager defaultControlsViewStrategy]];
    self.playbackController.delegate = self;
    self.playbackController.autoAdvance = YES;
    self.playbackController.autoPlay = YES;

    // Creating a playback controller based on the above code will create
    // VMAP / Server Side Ad Rules. These settings are explained in BCOVIMAAdsRequestPolicy.h.
    // If you want to change these settings, you can initialize the plugin like so:
    //
    // BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:kViewControllerIMAVMAPResponseAdTag];
    //
    // or for VAST:
    //
    // BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVASTAdTagsInCuePointsAndAdsCuePointProgressPolicy:[BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:nil]];

    
    
    // With a custom view strategy, the ad container view and ad companion slots can be tied with the video content view.
    // BCOVPlaybackControllerViewStrategy viewStrategy = ^UIView* (UIView *view, id<BCOVPlaybackController> playbackController){
        
    //        BCOVPlaybackControllerViewStrategy defaultControlsViewStrategy = [manager defaultControlsViewStrategy];
    //        UIView *contentAndDefaultControlsView = defaultControlsViewStrategy(view, playbackController);
    //
    // Make sure the content view won't cover the any subviews (ad view) in ad container view.
    //        [self.videoContainer addSubview:contentAndDefaultControlsView];
    //
    //        return self.videoContainer;
    // };
    //
    // _playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings adsRenderingSettings:renderSettings adsRequestPolicy:adsRequestPolicy viewStrategy:viewStrategy];
    //
    
    
    self.catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];

    [self resumeAdAfterForeground];
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
    // catalog service.  The data in the catalog does not have the required
    // VMAP tag on the video, so this code demonstrates how to update a playlist
    // to set the ad tags on the video.
    // You are responsible for determining where the ad tag should originate from.
    // We advise that if you choose to hard code it into your app, that you provide
    // a mechanism to update it without having to submit an update to your app.

    [self.catalogService findPlaylistWithPlaylistID:kViewControllerPlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {

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
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined BCOVIMAComponent.h.

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
