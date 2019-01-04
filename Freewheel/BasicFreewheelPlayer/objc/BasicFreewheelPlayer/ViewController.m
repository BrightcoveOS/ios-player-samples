//
//  ViewController.m
//  BasicFreewheelPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//


@import BrightcoveFW;

#import <AdManager/FWSDK.h>

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";

static NSString * const kViewControllerSlotId= @"300x250";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, weak) BCOVFWContext *bcovAdContext;
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
    [_adManager setNetworkId:42015];

    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    BCOVFWSessionProviderOptions *options = [[BCOVFWSessionProviderOptions alloc] init];
    options.cuePointProgressPolicy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessFinalCuePoint resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead ignoringPreviouslyProcessedCuePoints:YES];

    id<BCOVPlaybackSessionProvider> sessionProvider = [manager createFWSessionProviderWithAdContextPolicy:[self adContextPolicy] upstreamSessionProvider:nil options:options];

    // Creating a playback controller based on this code will initialize a Freewheel component using its default settings.
    // See BCOVFWSessionProvider.h for details.
    // _playbackController = [manager createFWPlaybackControllerWithAdContextPolicy:[self adContextPolicy] viewStrategy:nil];
    
    _playbackController = [manager createPlaybackControllerWithSessionProvider:sessionProvider viewStrategy:nil];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                            policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:_playbackController options:nil controlsView:controlView];
    _playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [_videoContainerView addSubview:_playerView];
    [NSLayoutConstraint activateConstraints:@[
                                              [_playerView.topAnchor constraintEqualToAnchor:_videoContainerView.topAnchor],
                                              [_playerView.rightAnchor constraintEqualToAnchor:_videoContainerView.rightAnchor],
                                              [_playerView.leftAnchor constraintEqualToAnchor:_videoContainerView.leftAnchor],
                                              [_playerView.bottomAnchor constraintEqualToAnchor:_videoContainerView.bottomAnchor],
                                            ]];
    _playerView.playbackController = _playbackController;

    [self requestContentFromPlaybackService];
}

- (BCOVFWSessionProviderAdContextPolicy)adContextPolicy
{
    ViewController * __weak weakSelf = self;

    return [^ BCOVFWContext * (BCOVVideo *video, BCOVSource *source, NSTimeInterval videoDuration) {

        ViewController *strongSelf = weakSelf;

        // This block will get called before every session is delivered. The source,
        // video, and videoDuration are provided in case you need to use them to
        // customize the these settings.
        // The values below are specific to this sample app, and should be changed
        // appropriately. For information on what values need to be provided,
        // please refer to your Freewheel documentation or contact your Freewheel
        // account executive. Basic information is provided below.
        id<FWContext> adContext = [strongSelf.adManager newContext];
        
        // These are player/app-specific and asset-specific values.
        FWRequestConfiguration *adRequestConfig = [[FWRequestConfiguration alloc] initWithServerURL:@"http://cue.v.fwmrm.net" playerProfile:@"96749:global-cocoa"];
        adRequestConfig.siteSectionConfiguration = [[FWSiteSectionConfiguration alloc] initWithSiteSectionId:@"DemoSiteGroup.01" idType:FWIdTypeCustom];
        adRequestConfig.videoAssetConfiguration = [[FWVideoAssetConfiguration alloc] initWithVideoAssetId:@"DemoVideoGroup.01" idType:FWIdTypeCustom duration:160 durationType:FWVideoAssetDurationTypeExact autoPlayType:FWVideoAssetAutoPlayTypeAttended];
        
        // This is the view where the ads will be rendered.
        [adContext setVideoDisplayBase:strongSelf.playerView.contentOverlayView];

        // These are required to use Freewheel's OOTB ad controls.
        [adContext setParameter:FWParameterDetectClick withValue:@"NO" forLevel:FWParameterLevelGlobal];

        // This registers a companion view slot with size 300x250. If you don't
        // need companion ads, this can be removed.
        [adRequestConfig addSlotConfiguration:[[FWNonTemporalSlotConfiguration alloc] initWithCustomId:kViewControllerSlotId adUnit:FWAdUnitOverlay width:300 height:250]];

        [adRequestConfig addSlotConfiguration:[[FWTemporalSlotConfiguration alloc] initWithCustomId:@"midroll60" adUnit:FWAdUnitMidroll timePosition:60.0]];
        [adRequestConfig addSlotConfiguration:[[FWTemporalSlotConfiguration alloc] initWithCustomId:@"midroll120" adUnit:FWAdUnitMidroll timePosition:120.0]];

        BCOVFWContext *bcovAdContext = [[BCOVFWContext alloc] initWithAdContext:adContext requestConfiguration:adRequestConfig];
        
        // We save the adContext to the class so that we can access outside the
        // block. In this case, we will need to retrieve the companion ad slot.
        strongSelf.bcovAdContext = bcovAdContext;

        return bcovAdContext;
        
    } copy];
}

- (void)requestContentFromPlaybackService
{
    // In order to play back content, we are going to request a video from the playback service.
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {

        if (video)
        {
            [self.playbackController setVideos:@[ video ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: %@", error);
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
    id<FWSlot> slot = [self.bcovAdContext.adContext getSlotByCustomId:kViewControllerSlotId];

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

