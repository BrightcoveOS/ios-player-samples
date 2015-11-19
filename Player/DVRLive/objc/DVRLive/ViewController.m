//
//  ViewController.m
//  VideoCloudBasicPlayer
//
//  Copyright (c) 2015 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

@import BrightcovePlayerSDK;


static NSString * const kVideoURLString = <URL of Live HLS>;

static NSString * const kPlayPauseButtonTitlePlay = @"Play";
static NSString * const kPlayPauseButtonTitlePause = @"Pause";

@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) id<BCOVPlaybackSession> currentSession;

@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *liveButton;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

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
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createPlaybackControllerWithViewStrategy:nil];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.playbackController.view.frame = self.videoContainer.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer addSubview:self.playbackController.view];

    NSURL *videoURL = [NSURL URLWithString:kVideoURLString];
    BCOVSource *source = [[BCOVSource alloc] initWithURL:videoURL deliveryMethod:kBCOVSourceDeliveryHLS properties:nil];
    BCOVVideo *video = [[BCOVVideo alloc] initWithSource:source cuePoints:nil properties:nil];
    [self.playbackController setVideos:@[video]];
}


#pragma mark IBAction

- (IBAction)playPauseButtonDidTouchUpInside:(UIButton *)playPauseButton
{
    if ([playPauseButton.titleLabel.text isEqualToString:kPlayPauseButtonTitlePlay])
    {
        [self.currentSession.player play];
    }
    else
    {
        [self.currentSession.player pause];
    }

}

- (IBAction)progressSliderDidTouchUpInsideOutside:(UISlider *)progressSlider
{
    AVPlayer *player = self.currentSession.player;
    NSValue *value = player.currentItem.seekableTimeRanges.lastObject;
    if (!value)
    {
        return;
    }
    
    CMTimeRange seekableTimeRange = value.CMTimeRangeValue;
    float percentage = progressSlider.value;
    CMTime seekToTime = [self timeWithTimeRange:seekableTimeRange percentage:percentage];
    
    [self seekToTimeWithPlayer:player time:seekToTime];
}

- (IBAction)progressSliderValueDidChange:(UISlider *)progressSlider
{
    float percentage = progressSlider.value;
    self.liveButton.enabled = (percentage < .95);
}

- (IBAction)liveButtonDidTouchUpInside:(UIButton *)liveButton
{
    AVPlayer *player = self.currentSession.player;
    NSValue *value = player.currentItem.seekableTimeRanges.lastObject;
    if (!value)
    {
        return;
    }
    
    CMTimeRange seekableTimeRange = value.CMTimeRangeValue;
    CMTime seekToTime = [self timeWithTimeRange:seekableTimeRange percentage:1.0];
    
    [self seekToTimeWithPlayer:player time:seekToTime];
}

- (CMTime)timeWithTimeRange:(CMTimeRange)timeRange percentage:(float)percentage
{
    if (percentage >= 1.0)
    {
        return CMTimeRangeGetEnd(timeRange);
    }
    Float64 start = CMTimeGetSeconds(timeRange.start);
    Float64 end = CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange));
    
    Float64 seekToSecond = percentage * (end - start) + start;
    return CMTimeMakeWithSeconds(seekToSecond, timeRange.start.timescale);
}

- (void)seekToTimeWithPlayer:(AVPlayer *)player time:(CMTime)time
{
    [player pause];
    [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
        [player play];
        
    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"ViewController Debug - Received lifecycle event.");
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventPlay])
    {
        [self.playPauseButton setTitle:kPlayPauseButtonTitlePause forState:UIControlStateNormal];
    }
    else if([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventPause])
    {
        [self.playPauseButton setTitle:kPlayPauseButtonTitlePlay forState:UIControlStateNormal];
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
    self.currentSession = session;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    AVPlayerItem *item = session.player.currentItem;
    NSValue *value = item.seekableTimeRanges.lastObject;
    if (!value)
    {
        return;
    }
    
    CMTimeRange seekableTimeRange = value.CMTimeRangeValue;
    Float64 start = CMTimeGetSeconds(seekableTimeRange.start);
    Float64 end = CMTimeGetSeconds(CMTimeRangeGetEnd(seekableTimeRange));
    Float64 currentTime = CMTimeGetSeconds(item.currentTime);
    Float64 percentage = (currentTime - start) / (end - start);
    
    if (percentage > 1.0)
    {
        percentage = 1.0;
    }
    else if(percentage <= 0)
    {
        percentage = .0;
    }
    
    self.progressSlider.value = percentage;
    
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

