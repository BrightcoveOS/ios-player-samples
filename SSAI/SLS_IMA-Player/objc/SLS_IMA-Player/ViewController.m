//
//  ViewController.m
//  SLS_IMA-Player
//
//  Created by Carlos Ceja on 13/07/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import "ViewController.h"

@import GoogleInteractiveMediaAds;

@import BrightcovePlayerSDK;
@import BrightcoveSSAI;
@import BrightcoveIMA;


static NSString * const kViewControllerAccountID = @"insertyouraccountidhere";
static NSString * const kViewControllerPlaybackServicePolicyKey = @"insertyourpolicykeyhere";
static NSString * const kViewControllerVideoID = @"insertyourvideoidhere";

static NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
static NSString * const kViewControllerIMALanguage = @"en";
static NSString * const kViewControllerIMAVMAPResponseAdTag = @"insertyouradtaghere";

static NSString * const kViewControllerAdConfigID = @"insertyouradconfigidhere";


@interface ViewController ()<BCOVPlaybackControllerDelegate, BCOVPlaybackControllerAdsDelegate, IMAWebOpenerDelegate>

@property (weak, nonatomic) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupPlayerView];
    [self setupPlaybackController];
    [self setupPlaybackService];
    [self requestContentFromPlaybackService];
}

- (void)setupPlayerView
{
    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithLiveLayout];
    self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:nil controlsView:controlView];
    
    [self.videoContainerView addSubview:self.playerView];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
        [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
        [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
        [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
    ]];
}

- (void)setupPlaybackController
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
    
    // BCOVIMAPlaybackSessionDelegate defines -willCallIMAAdsLoaderRequestAdsWithRequest:forPosition: which allows us to modify the IMAAdsRequest object
    // before it is used to load ads.
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };
    
    id basicSessionProvider = [manager createBasicSessionProviderWithOptions:nil];
    id imaSessionProvider = [manager createIMASessionProviderWithSettings:imaSettings adsRenderingSettings:renderSettings adsRequestPolicy:adsRequestPolicy adContainer:self.playerView.contentOverlayView companionSlots:@[] upstreamSessionProvider:basicSessionProvider options:imaPlaybackSessionOptions];
    id ssaiSessionProvider = [manager createSSAISessionProviderWithUpstreamSessionProvider:imaSessionProvider];
    
    self.playbackController = [manager createPlaybackControllerWithSessionProvider:ssaiSessionProvider viewStrategy:nil];
    self.playbackController.delegate = self;
    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;

    self.playerView.playbackController = self.playbackController;
}

- (void)setupPlaybackService
{
    BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:kViewControllerAccountID policyKey:kViewControllerPlaybackServicePolicyKey];
    self.playbackService = [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *queryParmaters = @{ kBCOVPlaybackServiceParamaterKeyAdConfigId: kViewControllerAdConfigID };
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:queryParmaters completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {
                
                // The BCOVIMA plugin will look for the presence of kBCOVIMAAdTag in
                // the video's properties when using server side ad rules. This URL returns
                // a VMAP response that is handled by the Google IMA library.
                NSDictionary *adProperties = @{ kBCOVIMAAdTag : kViewControllerIMAVMAPResponseAdTag };
                
                NSMutableDictionary *propertiesToUpdate = [mutableVideo.properties mutableCopy];
                [propertiesToUpdate addEntriesFromDictionary:adProperties];
                mutableVideo.properties = propertiesToUpdate;
                
            }];
            
            [weakSelf.playbackController setVideos:@[ updatedVideo ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video: %@", error.localizedDescription ?: @"unknown error");
        }
        
    }];
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}


#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController Debug - Entering ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController Debug - Exiting ad sequence");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAd:(BCOVAd *)ad
{
    NSLog(@"ViewController Debug - Entering ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAd:(BCOVAd *)ad
{
    NSLog(@"ViewController Debug - Exiting ad");
}


#pragma mark - IMAWebOpenerDelegate

- (void)webOpenerDidOpenInAppBrowser:(NSObject *)webOpener {
    NSLog(@"ViewController Debug - webOpenerDidOpenInAppBrowser");
}

- (void)webOpenerDidCloseInAppBrowser:(NSObject *)webOpener {
    NSLog(@"ViewController Debug - webOpenerDidCloseInAppBrowser");
}

@end
