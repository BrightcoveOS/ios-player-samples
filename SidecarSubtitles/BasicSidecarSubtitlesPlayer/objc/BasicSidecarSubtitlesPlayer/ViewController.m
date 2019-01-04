//
//  ViewController.m
//  BasicSidecarSubtitlesPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

/*
 * This sample app shows how to retrieve a video from Video Cloud
 * and add a sidecar VTT captions file to it for playback.
 *
 * The interesting methods in the code are `-requestContentFromPlaybackService` and
 * `-setupSubtitles`.
 *
 * `-requestContentFromPlaybackService` retrieves a video from Video Cloud
 * normally, but then it creates an array of text tracks, and adds them to the
 * BCOVVideo object. BCOVVideo is an immutable object, but you can create a new
 * modified copy of it by calling `BCOVVideo update:`.
 *
 * `-setupSubtitles` creates the array of subtitle dictionaries.
 * When creating these dictionaries, be sure to make note of which fields
 * are required are optional as specified in BCOVSSComponent.h.
 *
 * Note that in this sample the subtitle track does not match the audio of the
 * video; it's only used as an example.
 *
 */

#import "ViewController.h"

@import BrightcovePlayerSDK;

@import MediaPlayer;
@import AVFoundation;
@import AVKit;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm";
static NSString * const kViewControllerAccountID = @"3636334163001";
static NSString * const kViewControllerVideoID = @"3666678807001";

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create Player View (PlayerUI)
    [self createPlayerView];

    {
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        
        // Create the Playback Controller
        self.playbackController = [manager createSidecarSubtitlesPlaybackControllerWithViewStrategy:nil];
        self.playbackController.delegate = self;
        self.playbackController.autoAdvance = YES;
        self.playbackController.autoPlay = YES;
    }

    // Link the playback controller to the player view
    self.playerView.playbackController = self.playbackController;

    // Instantiate Playback Service
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID policyKey:kViewControllerPlaybackServicePolicyKey];

    [self requestContentFromPlaybackService];
}

- (void)createPlayerView
{
    if (self.playerView == nil)
    {
        // Create PlayerUI views with normal VOD controls.
        BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
        self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil // can set this later
                                                                        options:nil
                                                                   controlsView:controlView];
        
        // Add to parent view
        [self.videoContainerView addSubview:self.playerView];
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
                                                  [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
                                                  [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
                                                  [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
                                                  ]];
    }
}

- (void)requestContentFromPlaybackService
{
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            // Add subtitle track to video object
            BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {

                // Get the existing text tracks, if any
                NSArray *currentTextTracks = mutableVideo.properties[kBCOVSSVideoPropertiesKeyTextTracks];

                // Get the subtitles array
                NSArray *newTextTracks = [self setupSubtitles];

                // Combine the two arrays together.
                // We don't want to lose the original tracks that might already be in there.
                NSArray *combinedTextTracks = ((currentTextTracks != nil)
                                               ? [currentTextTracks arrayByAddingObjectsFromArray:newTextTracks]
                                               : newTextTracks);
                
                // Update the current dictionary (we don't want to lose the properties already in there)
                NSMutableDictionary *updatedDictionary = [mutableVideo.properties mutableCopy];

                // Store text tracks in the text tracks property
                updatedDictionary[kBCOVSSVideoPropertiesKeyTextTracks] = combinedTextTracks;
                mutableVideo.properties = updatedDictionary;

            }];

            [self.playbackController setVideos:@[ updatedVideo ]];
        }
        else
        {
            NSLog(@"Error retrieving video playlist: `%@`", error);
        }
        
    }];
}

- (NSArray *)setupSubtitles
{
    // Create the array of subtitle dictionaries
    NSArray *textTracks =
    @[
      @{
          // required tracks descriptor: kBCOVSSTextTracksKindSubtitles or kBCOVSSTextTracksKindCaptions
          kBCOVSSTextTracksKeyKind: kBCOVSSTextTracksKindSubtitles,
          
          // required language code
          kBCOVSSTextTracksKeySourceLanguage: @"en",
          
          // required display name
          kBCOVSSTextTracksKeyLabel: @"English",
          
          // required: source URL of WebVTT file or playlist as NSString
          kBCOVSSTextTracksKeySource: @"http://players.brightcove.net/3636334163001/ios_native_player_sdk/vtt/sample.vtt",
          
          // optional MIME type
          kBCOVSSTextTracksKeyMIMEType: @"text/vtt",
          
          // optional "default" indicator
          kBCOVSSTextTracksKeyDefault: @YES,
          
          // duration is required for WebVTT URLs (ending in ".vtt");
          // optional for WebVTT playlists (ending in ".m3u8")
          kBCOVSSTextTracksKeyDuration: @959, // seconds as NSNumber
          
          // The source type is only needed if your source URL
          // does not end in ".vtt" or ".m3u8" and thus its type is ambiguous.
          // Our URL ends in ".vtt" so we don't need to set this, but it won't hurt.
          kBCOVSSTextTracksKeySourceType: kBCOVSSTextTracksKeySourceTypeWebVTTURL
          
          }
      ];
    
    return textTracks;
}

#pragma mark - BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"Received lifecycle event: %@", lifecycleEvent.eventType);
}

@end
