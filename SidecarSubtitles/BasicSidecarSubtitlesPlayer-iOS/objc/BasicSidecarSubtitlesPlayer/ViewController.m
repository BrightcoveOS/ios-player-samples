//
//  ViewController.m
//  BasicSidecarSubtitlesPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to retrieve a video from Video Cloud
 * and add a sidecar VTT captions file to it for playback.
 *
 * The interesting methods in the code are `-requestContentFromPlaybackService` and
 * `-textTracks`.
 *
 * `-requestContentFromPlaybackService` retrieves a video from Video Cloud
 * normally, but then it creates an array of text tracks, and adds them to the
 * BCOVVideo object. BCOVVideo is an immutable object, but you can create a new
 * modified copy of it by calling `BCOVVideo update:`.
 *
 * `-textTracks` creates the array of subtitle dictionaries.
 * When creating these dictionaries, be sure to make note of which fields
 * are required are optional as specified in BCOVSSComponent.h.
 *
 * Note that in this sample the subtitle track does not match the audio of the
 * video; it's only used as an example.
 *
 */

@import BrightcovePlayerSDK;

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"6140448705001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

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

    [self requestContentFromPlaybackService];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (NSArray *)textTracks
{
    // Create the array of subtitle dictionaries
    NSArray *textTracks =
    @[
        @{
            // required tracks descriptor: BCOVSSConstants.TextTracksKindSubtitles or BCOVSSConstants.TextTracksKindCaptions
            BCOVSSConstants.TextTracksKeyKind: BCOVSSConstants.TextTracksKindSubtitles,

            // required language code
            BCOVSSConstants.TextTracksKeySourceLanguage: @"en",

            // required display name
            BCOVSSConstants.TextTracksKeyLabel: @"English",

            // required: source URL of WebVTT file or playlist as NSString
            BCOVSSConstants.TextTracksKeySource: @"http://players.brightcove.net/3636334163001/ios_native_player_sdk/vtt/sample.vtt",

            // optional MIME type
            BCOVSSConstants.TextTracksKeyMIMEType: @"text/vtt",

            // optional "default" indicator
            BCOVSSConstants.TextTracksKeyDefault: @(YES),

            // duration is required for WebVTT URLs (ending in ".vtt");
            // optional for WebVTT playlists (ending in ".m3u8")
            BCOVSSConstants.TextTracksKeyDuration: @(959), // seconds as NSNumber

            // The source type is only needed if your source URL
            // does not end in ".vtt" or ".m3u8" and thus its type is ambiguous.
            // Our URL ends in ".vtt" so we don't need to set this, but it won't hurt.
            BCOVSSConstants.TextTracksKeySourceType: BCOVSSConstants.TextTracksKeySourceTypeWebVTTURL

        }
    ];

    return textTracks;
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

    self.playbackController = ({
        BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

        BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];

        id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithAuthorizationProxy:authProxy
                                                                                      upstreamSessionProvider:nil];

        id<BCOVPlaybackSessionProvider> sidecarSubtitlesSessionProvider = [sdkManager createSidecarSubtitlesSessionProviderWithUpstreamSessionProvider:fps];

        id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:sidecarSubtitlesSessionProvider
                                                                                                   viewStrategy:nil];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;

        self.playerView.playbackController = playbackController;

        playbackController;
    });
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;

    NSDictionary *configuration = @{ BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId };
    [self.playbackService findVideoWithConfiguration:configuration
                                     queryParameters:nil
                                          completion:^(BCOVVideo *video,
                                                       NSDictionary *jsonResponse,
                                                       NSError *error) {

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (video)
        {
#if TARGET_OS_SIMULATOR
            if (video.usesFairPlay)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FairPlay Warning"
                                                                               message:@"FairPlay only works on actual iOS or tvOS devices.\n\nYou will not be able to view any FairPlay content in the iOS or tvOS simulator."
                                                                        preferredStyle:UIAlertControllerStyleAlert];

                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                });

                return;
            }
#endif

            // Add subtitle track to video object
            BCOVVideo *updatedVideo = [video update:^(BCOVMutableVideo* mutableVideo) {

                // Get the existing text tracks, if any
                NSArray *currentTextTracks = mutableVideo.properties[BCOVSSConstants.VideoPropertiesKeyTextTracks];

                // Get the subtitles array
                NSArray *newTextTracks = [strongSelf textTracks];

                // Combine the two arrays together.
                // We don't want to lose the original tracks that might already be in there.
                NSArray *combinedTextTracks = ((currentTextTracks != nil)
                                               ? [currentTextTracks arrayByAddingObjectsFromArray:newTextTracks]
                                               : newTextTracks);

                // Update the current dictionary (we don't want to lose the properties already in there)
                NSMutableDictionary *updatedDictionary = [mutableVideo.properties mutableCopy];

                // Store text tracks in the text tracks property
                updatedDictionary[BCOVSSConstants.VideoPropertiesKeyTextTracks] = combinedTextTracks;
                mutableVideo.properties = updatedDictionary;

            }];

            [strongSelf.playbackController setVideos:@[ updatedVideo ]];
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


#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView
willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.statusBarHidden = screenMode == BCOVPUIScreenModeFull;
}

@end
