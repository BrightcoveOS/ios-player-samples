//
//  ViewController.m
//  SubtitleRendering
//
//  Created by Jeremy Blaker on 3/24/21.
//

#import "ViewController.h"
#import "SubtitleManager.h"

@import BrightcovePlayerSDK;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"5702141808001";

@interface ViewController ()<BCOVPUIPlayerViewDelegate, BCOVPlaybackControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) NSArray *textTracks;
@property (nonatomic, strong) SubtitleManager *subtitleManager;

@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *subtitlesLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *subtitlesBottomConstraint;

@end

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.subtitlesLabel.text = nil;
    
    [self setup];
    
    [self requestContentFromPlaybackService];
}

#pragma mark - Setup

- (void)setup
{
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];
    
    [self setupPlaybackController];
    [self setupPlayerView];
}

- (void)setupPlaybackController
{
    self.playbackController = [BCOVPlayerSDKManager.sharedManager createPlaybackController];

    self.playbackController.delegate = self;
    self.playbackController.autoPlay = YES;
}

- (void)setupPlayerView
{
    // Set up our player view. Create with a standard VOD layout.
    BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
    options.showPictureInPictureButton = YES;
    
    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout] ];
    playerView.delegate = self;

    [_videoContainer addSubview:playerView];
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [playerView.topAnchor constraintEqualToAnchor:_videoContainer.topAnchor],
                                              [playerView.rightAnchor constraintEqualToAnchor:_videoContainer.rightAnchor],
                                              [playerView.leftAnchor constraintEqualToAnchor:_videoContainer.leftAnchor],
                                              [playerView.bottomAnchor constraintEqualToAnchor:_videoContainer.bottomAnchor],
                                              ]];
    self.playerView = playerView;
    
    // Hide built-in CC button
    BCOVPUIButton *ccButton = self.playerView.controlsView.closedCaptionButton;
    ccButton.hidden = YES;

    // Associate the playerView with the playback controller.
    self.playerView.playbackController = self.playbackController;
}

#pragma mark - Helper Methods

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (video)
        {
            [strongSelf gatherUsableTextTracks:video];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
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
    
    self.textTracks = usableTextTracks;
    [self.tableView reloadData];
    
    // If we have text tracks go ahead and
    // select the first one
    if (self.textTracks.count > 0)
    {
        [self useTextTrack:self.textTracks.firstObject];
    }
    
    // Now update the BCOVVideo with our new text tracks array
    video = [video update:^(id<BCOVMutableVideo>  _Nonnull mutableVideo) {
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

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Text Tracks";
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.textTracks.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextTrackCell"];
    
    if (indexPath.section == 0)
    {
        NSDictionary *textTrack = self.textTracks[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", textTrack[@"label"], textTrack[@"srclang"]];
    }
    else
    {
        cell.textLabel.text = @"Disable text track";
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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

#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    [self.videoContainer bringSubviewToFront:self.subtitlesLabel];
    
    // Position the subtitles container if the controls
    // are already visible
    if (self.playerView.controlsFadingViewVisible)
    {
        self.subtitlesBottomConstraint.constant = 100;
    }
    
    __weak typeof(self) weakSelf = self;
    [session.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.subtitleManager)
        {
            NSString *subtitle = [strongSelf.subtitleManager subtitleForTime:time];
            strongSelf.subtitlesLabel.text = subtitle;
        }
        
    }];
}

#pragma mark - BCOVPUIPlayerViewDelegate

- (void)playerView:(BCOVPUIPlayerView *)playerView controlsFadingViewDidFadeIn:(UIView *)controlsFadingView
{
    // Move the subtitle container up so it isn't
    // hidden by the controls
    [UIView animateWithDuration:0.15 animations:^{
        self.subtitlesBottomConstraint.constant = 100;
        [self.view layoutIfNeeded];
    }];
}

- (void)playerView:(BCOVPUIPlayerView *)playerView controlsFadingViewDidFadeOut:(UIView *)controlsFadingView
{
    // Move the subtitle container back to the bottom
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.15 animations:^{
            self.subtitlesBottomConstraint.constant = 20;
            [self.view layoutIfNeeded];
        }];
    });
}

@end
