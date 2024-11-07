//
//  ViewController.m
//  SubtitleRendering
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;

#import "SubtitleManager.h"

#import "ViewController.h"


// Customize these values with your own account information
// Add your Brightcove account and video information here.
static NSString * const kAccountId = @"5434391461001";
static NSString * const kPolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kVideoId = @"5702141808001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UILabel *subtitlesLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;

@property (nonatomic, strong) NSArray *textTracks;
@property (nonatomic, strong) SubtitleManager *subtitleManager;

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
    
    self.subtitlesLabel.text = nil;
    
    self.playbackService = ({
        BCOVPlaybackServiceRequestFactory *factory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                      initWithAccountId:kAccountId
                                                      policyKey:kPolicyKey];
        
        [[BCOVPlaybackService alloc] initWithRequestFactory:factory];
    });
    
    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        options.presentingViewController = self;
        
        BCOVPUIBasicControlView *controlsView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
        
        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:controlsView];
        
        // Hide built-in CC button
        BCOVPUIButton *ccButton = playerView.controlsView.closedCaptionButton;
        ccButton.hidden = YES;
        
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
        
        id<BCOVPlaybackController> playbackController = [sdkManager
                                                         createPlaybackControllerWithSessionProvider:fps
                                                         viewStrategy:nil];
        
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        
        self.playerView.playbackController = playbackController;
        
        playbackController;
    });
    
    [self requestContentFromPlaybackService];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
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
            
            [strongSelf gatherUsableTextTracks:video];
        }
        else
        {
            NSLog(@"ViewController - Error retrieving video: %@", error.localizedDescription);
        }
        
    }];
}

- (void)gatherUsableTextTracks:(BCOVVideo *)video
{
    // We need to get an array of available text tracks
    // for this video. In this case we are going to use the
    // `text_tracks` array on this video's properties dictionary.
    // We're also going to set the `default` value of any of these
    // text tracks to ensure that AVPlayer doesn't select a track
    // automatically and attempt to render it itself.
    NSArray *allTextTracks = video.properties[@"text_tracks"];
    NSMutableArray *usableTextTracks = @[].mutableCopy;
    
    for (NSDictionary *textTrack in allTextTracks)
    {
        NSString *kind = textTrack[@"kind"];
        if ([kind isEqualToString:@"captions"] || [kind isEqualToString:@"subtitles"])
        {
            NSMutableDictionary *_textTrack = textTrack.mutableCopy;
            _textTrack[@"default"] = @(NO);
            [usableTextTracks addObject:_textTrack];
        }
    }
    
    self.textTracks = usableTextTracks.copy;
    [self.tableView reloadData];
    
    // If we have text tracks go ahead and
    // select the first one
    if (self.textTracks.count > 0)
    {
        [self useTextTrack:self.textTracks.firstObject];
    }
    
    // Now update the BCOVVideo with our new text tracks array
    video = [video update:^(BCOVMutableVideo* mutableVideo) {
        NSMutableDictionary *props = mutableVideo.properties.mutableCopy;
        props[@"text_tracks"] = usableTextTracks;
        mutableVideo.properties = props;
    }];
    
    [self.playbackController setVideos:@[ video ]];
}

- (void)useTextTrack:(NSDictionary *)textTrack
{
    // Look for an HTTPS source
    NSArray *sources = textTrack[@"sources"];
    NSString *httpsSource;
    
    for (NSDictionary *srcDict in sources)
    {
        NSString *src = srcDict[@"src"];
        if ([src hasPrefix:@"https://"])
        {
            httpsSource = src;
            break;
        }
    }
    
    // If no HTTPS src is found fallback to default src
    NSString *src = httpsSource ?: textTrack[@"src"];
    
    NSURL *subtitleURL = [NSURL URLWithString:src];
    
    if (subtitleURL)
    {
        self.subtitleManager = [[SubtitleManager alloc] initWithURL:subtitleURL];
    }
    else
    {
        NSLog(@"Couldn't create URL from text track src");
    }
}


#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller
didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController - Advanced to new session.");
    
    // When Closed Captions + SDK is anabled in the device settings, Subtitles and
    // Closed-Captions tracks might be forcibly rendered over the video. Rendering them
    // also in a separate UIView may be undesirable.
    if (UIAccessibilityIsClosedCaptioningEnabled())
    {
        NSLog(@"WARNING: Closed Captions + SDH is enabled in the device Accessibility settings.");
        NSLog(@"         A text track might be forcibly rendered in the video view.");
    }
    
    __weak typeof(self) weakSelf = self;
    [session.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60)
                                                 queue:dispatch_get_main_queue()
                                            usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.subtitleManager)
        {
            NSString *subtitle = [strongSelf.subtitleManager subtitleForTime:time];
            strongSelf.subtitlesLabel.text = subtitle;
        }
    }];
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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0)
    {
        NSDictionary *textTrack = self.textTracks[indexPath.row];
        [self useTextTrack:textTrack];
    }
    else
    {
        self.subtitleManager = nil;
        self.subtitlesLabel.text = nil;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.textTracks.count : 1;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"Text Tracks" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextTrackCell"];
    
    if (indexPath.section == 0)
    {
        NSDictionary *textTrack = self.textTracks[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", 
                               textTrack[@"label"],
                               textTrack[@"srclang"]];
    }
    else
    {
        cell.textLabel.text = @"Disable text track";
    }
    
    return cell;
}

@end
