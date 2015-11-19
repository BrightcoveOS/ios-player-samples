//
//  ViewController.m
//  BasicFreewheelPlayer
//
//  Created by Mike Moscardini on 10/27/14.
//  Copyright (c) 2014 BrightCove. All rights reserved.
//


@import BrightcoveFW;

#import <AdManager/FWSDK.h>

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";

static NSString * const kViewControllerSlotId= @"300x250";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, weak) id<FWContext> adContext;
@property (nonatomic, strong) id<FWAdManager> adManager;
@property (nonatomic, weak) IBOutlet UIView *adSlot;

@end


@implementation ViewController

#pragma mark Setup Methods

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
    // The FWAdManager will be responsible for creating all the ad contexts.
    // We use it in the BCOVFWSessionProviderAdContextPolicy created by
    // the -[ViewController adContextPolicy] block.
    _adManager = newAdManager();
    [_adManager setNetworkId:90750];
    [_adManager setServerUrl:@"http://demo.v.fwmrm.net"];

    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createFWPlaybackControllerWithAdContextPolicy:[self adContextPolicy] viewStrategy:[manager defaultControlsViewStrategy]];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    // Creating a playback controller based on the above code will initialize a
    // Freewheel component using it's default settings. These settings and defaults
    // are explained in BCOVFWSessionProviderOptions.h.
    // If you want to change these settings, you can initialize the plugin like so:
    //
    // BCOVFWSessionProviderOptions *options = [[BCOVFWSessionProviderOptions alloc] init];
    // options.cuePointProgressPolicy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:resumingPlaybackFrom:ignoringPreviouslyProcessedCuePoints:];
    // id<BCOVPlaybackSessionProvider> sessionProvider = [playbackManager createFWSessionProviderWithAdContextPolicy:[self adContextPolicy] upstreamSessionProvider:nil options:options];
    //
    // id<BCOVPlaybackController> playbackController = [playbackManager createPlaybackControllerWithSessionProvider:sessionProvider viewStrategy:[playbackManager defaultControlsViewStrategy]];

    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.playbackController.view.frame = self.videoContainerView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainerView addSubview:self.playbackController.view];

    [self requestContentFromCatalog];
}

- (BCOVFWSessionProviderAdContextPolicy)adContextPolicy
{
    ViewController * __weak weakSelf = self;

    return [^ id<FWContext>(BCOVVideo *video, BCOVSource *source, NSTimeInterval videoDuration) {

        ViewController *strongSelf = weakSelf;

        // This block will get called before every session is delivered. The source,
        // video, and videoDuration are provided in case you need to use them to
        // customize the these settings.
        // The values below are specific to this sample app, and should be changed
        // appropriately. For information on what values need to be provided,
        // please refer to your Freewheel documentation or contact your Freewheel
        // account executive. Basic information is provided below.
        id<FWContext> adContext = [strongSelf.adManager newContext];

        // These are player/app specific values.
        [adContext setPlayerProfile:@"90750:3pqa_ios" defaultTemporalSlotProfile:nil defaultVideoPlayerSlotProfile:nil defaultSiteSectionSlotProfile:nil];
        [adContext setSiteSectionId:@"brightcove_ios" idType:FW_ID_TYPE_CUSTOM pageViewRandom:0 networkId:0 fallbackId:0];

        // This is an asset specific value.
        [adContext setVideoAssetId:@"brightcove_demo_video" idType:FW_ID_TYPE_CUSTOM duration:videoDuration durationType:FW_VIDEO_ASSET_DURATION_TYPE_EXACT location:nil autoPlayType:true videoPlayRandom:0 networkId:0 fallbackId:0];

        // This is the view where the ads will be rendered.
        [adContext setVideoDisplayBase:strongSelf.videoContainerView];

        // These are required to use Freewheel's OOTB ad controls.
        [adContext setParameter:FW_PARAMETER_USE_CONTROL_PANEL withValue:@"YES" forLevel:FW_PARAMETER_LEVEL_GLOBAL];
        [adContext setParameter:FW_PARAMETER_CLICK_DETECTION withValue:@"NO" forLevel:FW_PARAMETER_LEVEL_GLOBAL];

        // This registers a companion view slot with size 300x250. If you don't
        // need companion ads, this can be removed.
        [adContext addSiteSectionNonTemporalSlot:kViewControllerSlotId adUnit:nil width:300 height:250 slotProfile:nil acceptCompanion:YES initialAdOption:FW_SLOT_OPTION_INITIAL_AD_STAND_ALONE acceptPrimaryContentType:nil acceptContentType:nil compatibleDimensions:nil];

        // We save the adContext to the class so that we can access outside the
        // block. In this case, we will need to retrieve the companion ad slot.
        strongSelf.adContext = adContext;

        return adContext;
        
    } copy];
}

- (void)requestContentFromCatalog
{
    // In order to play back content, we are going to request a playlist from the
    // catalog service.
    [self.catalogService findPlaylistWithPlaylistID:kViewControllerPlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {

        if (playlist)
        {
            [self.playbackController setVideos:playlist];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving playlist: %@", error);
        }
        
    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods 

-(void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");

    // This is an example of displaying a companion ad. We registered this companion
    // ad id in the -[ViewController adContextPolicy] block. When the session
    // gets delivered, we check to see if the slot got populated with an ad,
    // and add it to our companion ad container.
    // If not using companion ads, this is not needed.
    id<FWSlot> slot = [self.adContext getSlotByCustomId:kViewControllerSlotId];

    if (slot)
    {
        slot.slotBase.frame = self.adSlot.bounds;
        slot.slotBase.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.adSlot addSubview:slot.slotBase];
    }
    
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

