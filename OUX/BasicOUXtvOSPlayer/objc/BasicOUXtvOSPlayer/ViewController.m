//
//  ViewController.m
//  BasicOUXtvOSPlayer
//
//  Copyright © 2017 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveOUX;

// Sample Once URL
static NSString *kViewControllerVideoURLString = @"http://once.unicornmedia.com/now/ads/vmap/od/auto/c501c3ee-7f1c-4020-aa6d-0b1ef0bbd4a9/354a749c-217b-498e-b4f9-c48cd131f807/66496c0e-6969-41b1-859f-9bdf288cfdd3/content.once";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;

// currentSession is weak so that it can be released properly
@property (nonatomic, weak) id<BCOVPlaybackSession> currentSession;

@property (nonatomic) NSTimeInterval currentTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) BOOL playingAdSequence;

@property (nonatomic) UILabel *currentTimeLabel;
@property (nonatomic) UILabel *durationLabel;

@property (nonatomic) UIView *topDrawerView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set up our playback controller
    self.playbackController = [[BCOVPlayerSDKManager sharedManager] createOUXPlaybackControllerWithViewStrategy:nil];
    
    self.playbackController.delegate = self;
    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.playbackController.view.frame = self.view.bounds;
    [self.view addSubview:self.playbackController.view];
    
    // Create video
    BCOVVideo *video = [BCOVVideo videoWithURL:[NSURL URLWithString:kViewControllerVideoURLString]];
    [self.playbackController setVideos:@[video]];

    [self installGestureRecognizers];
}

#pragma mark - Gesture Recognizers

- (void)installGestureRecognizers
{
    // Detect button presses
    // "Arrows" are taps on the trackpad
    [self addTapGestureRecognizerWithPressType:UIPressTypeUpArrow selector:@selector(upArrow:)];
    [self addTapGestureRecognizerWithPressType:UIPressTypeDownArrow selector:@selector(downArrow:)];
    [self addTapGestureRecognizerWithPressType:UIPressTypeLeftArrow selector:@selector(leftArrow:)];
    [self addTapGestureRecognizerWithPressType:UIPressTypeRightArrow selector:@selector(rightArrow:)];
    [self addTapGestureRecognizerWithPressType:UIPressTypeSelect selector:@selector(selection:)];
    [self addTapGestureRecognizerWithPressType:UIPressTypePlayPause selector:@selector(playPause:)];

    // This is for demo purposes only. Don't add a gesture for the menu button in your top-level controller.
    [self addTapGestureRecognizerWithPressType:UIPressTypeMenu selector:@selector(menu:)];

    // Detect swipes on the Siri Remote's trackpad
    [self addSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionLeft selector:@selector(swipeLeft:)];
    [self addSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionRight selector:@selector(swipeRight:)];
    [self addSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionUp selector:@selector(swipeUp:)];
    [self addSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionDown selector:@selector(swipeDown:)];
}

- (void)addTapGestureRecognizerWithPressType:(UIPressType)pressType selector:(SEL)selector
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
    tapRecognizer.allowedPressTypes = @[ @(pressType) ];
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)addSwipeGestureRecognizerWithDirection:(UISwipeGestureRecognizerDirection)direction selector:(SEL)selector
{
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:selector];
    swipeRecognizer.direction = direction;
    [self.view addGestureRecognizer:swipeRecognizer];
}

- (void)upArrow:(UITapGestureRecognizer *)upArrowRecognizer
{
    NSLog(@"upArrow");
    [self showMessage:@"Up Arrow"];
}

- (void)downArrow:(UITapGestureRecognizer *)downArrowRecognizer
{
    NSLog(@"downArrow");
    [self showMessage:@"Down Arrow"];
}

- (void)leftArrow:(UITapGestureRecognizer *)leftArrowRecognizer
{
    NSLog(@"leftArrow");

    if (!self.playingAdSequence)
    {
        [self showMessage:@"Seeking backwards 5 seconds"];
        [self seek:-5];
    }
    else
    {
        [self showMessage:@"Cannot seek during ad"];
    }
}

- (void)rightArrow:(UITapGestureRecognizer *)rightArrowRecognizer
{
    NSLog(@"rightArrow");

    if (!self.playingAdSequence)
    {
        [self showMessage:@"Seeking forwards 5 seconds"];
        [self seek:5];
    }
    else
    {
        [self showMessage:@"Cannot seek during ad"];
    }
}

- (void)selection:(UITapGestureRecognizer *)selectionRecognizer
{
    NSLog(@"select");

    if (self.playbackController)
    {
        BOOL playing = self.currentSession.player.rate > 0.1;
        
        if (playing)
        {
            [self showMessage:@"Pause"];
            [self.playbackController pause];
        }
        else
        {
            [self showMessage:@"Play"];
            [self.playbackController play];
        }
    }
}

- (void)menu:(UITapGestureRecognizer *)menuRecognizer
{
    // This gesture is usually disabled for your top-level view controller
    // so that the menu button will take you to the Apple TV home screen.
    NSLog(@"menu");

    [self showMessage:@"Menu button pressed"];
}

- (void)playPause:(UITapGestureRecognizer *)playPauseRecognizer
{
    NSLog(@"playPause");

    if (self.playbackController)
    {
        BOOL playing = self.currentSession.player.rate > 0.1;

        if (playing)
        {
            [self showMessage:@"Pause"];
            [self.playbackController pause];
        }
        else
        {
            [self showMessage:@"Play"];
            [self.playbackController play];
        }
    }
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)sender
{
    NSLog(@"swipe left");
    
    if (!self.playingAdSequence)
    {
        [self showMessage:@"Seeking backwards 15 seconds"];
        [self seek:-15];
    }
    else
    {
        [self showMessage:@"Cannot seek during ad"];
    }
}

- (void)swipeRight:(UISwipeGestureRecognizer *)sender
{
    NSLog(@"swipe right");
    
    if (!self.playingAdSequence)
    {
        [self showMessage:@"Seeking forwards 15 seconds"];
        [self seek:15];
    }
    else
    {
        [self showMessage:@"Cannot seek during ad"];
    }
}


- (void)swipeUp:(UISwipeGestureRecognizer *)sender
{
    NSLog(@"swipe up");
    
    [self showMessage:@"Swipe up"];
}

- (void)swipeDown:(UISwipeGestureRecognizer *)sender
{
    NSLog(@"swipe down");
    
    [self showMessage:@"Swipe down"];
}

- (void)seek:(NSTimeInterval)seconds
{
    CMTime skipToTime = CMTimeMake(self.currentTime + seconds, 1);

    [self.playbackController seekToTime:skipToTime completionHandler:^(BOOL finished) {

        NSLog(@"Seeked to time %.1f", CMTimeGetSeconds(skipToTime));

    }];
}

#pragma mark - BCOVPlaybackControllerBasicDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.currentSession = session;

    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    // Store time for display and seeking
    self.currentTime = progress;
    
    [self updateTimeLabels];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration
{
    // Store duration for display
    self.duration = duration;
}

#pragma mark - BCOVPlaybackControllerAdsDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController Debug - Entering ad sequence");
    [self showMessage:@"Entering ad sequence"];

    self.playingAdSequence = YES;

    // Hide labels during ads
    [self showTimeLabels:NO];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence
{
    NSLog(@"ViewController Debug - Exiting ad sequence");
    [self showMessage:@"Exiting ad sequence"];

    self.playingAdSequence = NO;

    // Show labels after ads end
    [self showTimeLabels:YES];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAd:(BCOVAd *)ad
{
    NSLog(@"ViewController Debug - Entering ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAd:(BCOVAd *)ad
{
    NSLog(@"ViewController Debug - Exiting ad");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    NSLog(@"ViewController Debug - Playlist complete; replaying video");
    [self.playbackController setVideos:playlist];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
//    NSLog(@"ViewController Debug - lifecycle event type: %@", lifecycleEvent.eventType);
}

#pragma mark - On-screen Message

- (void)showMessage:(NSString *)message
{
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.frame];
    label.text = message;
    label.textColor = [UIColor redColor];
    label.font = [UIFont boldSystemFontOfSize:96];
    [label sizeToFit];
    
    CGRect labelFrame = label.frame;
    CGRect labelBackgroundFrame = CGRectInset(labelFrame, -32.0, -20.0);
    UIView *labelBackgroundView = [[UIView alloc] initWithFrame:labelBackgroundFrame];
    labelBackgroundView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    labelBackgroundView.layer.cornerRadius = 50.0;
    
    [self.view addSubview:labelBackgroundView];
    [labelBackgroundView addSubview:label];
    labelBackgroundView.center = self.view.center;
    label.center = [labelBackgroundView convertPoint:labelBackgroundView.center fromView:labelBackgroundView.superview];

    // Now make everything go away
    [UIView animateWithDuration:1.0
                          delay:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^ {
                         
                         labelBackgroundView.alpha = 0.0;
                         
                     } completion:^(BOOL finished) {
                         
                         [label removeFromSuperview];
                         [labelBackgroundView removeFromSuperview];
                         
                     }];
}

#pragma mark - Time Labels

- (void)showTimeLabels:(BOOL)show
{
    self.currentTimeLabel.alpha = show ? 1.0 : 0.0;
    self.durationLabel.alpha = show ? 1.0 : 0.0;
}

- (void)updateTimeLabels
{
    // Apple-recommended minimum margins
    const float cSideMargin = 90.0;
    const float cBottomMargin = 60.0;

    const float cTimeLabelFontSize = 48;

    if (self.currentTimeLabel == nil)
    {
        // Create a current time label in the lower left corner.
        UILabel *label = [[UILabel alloc] initWithFrame:self.view.frame];
        label.text = @"00.00.00";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:cTimeLabelFontSize];
        [label sizeToFit];
        label.text = @"0.00";
        label.textAlignment = NSTextAlignmentLeft;
        
        CGRect labelFrame = label.frame;
        labelFrame.origin.x = cSideMargin;
        labelFrame.origin.y = self.view.frame.size.height - cBottomMargin - labelFrame.size.height;
        label.frame = labelFrame;
        
        [self.view addSubview:label];
        self.currentTimeLabel = label;
    }

    if (self.durationLabel == nil)
    {
        // Create a duration label in the lower left corner.
        UILabel *label = [[UILabel alloc] initWithFrame:self.view.frame];
        label.text = @"00.00.00";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:cTimeLabelFontSize];
        [label sizeToFit];
        label.text = @"0.00";
        label.textAlignment = NSTextAlignmentRight;
        
        CGRect labelFrame = label.frame;
        labelFrame.origin.x = self.view.frame.size.width - cSideMargin - labelFrame.size.width;
        labelFrame.origin.y = self.view.frame.size.height - cBottomMargin - labelFrame.size.height;
        label.frame = labelFrame;
        
        [self.view addSubview:label];
        self.durationLabel = label;
    }

    // Update label text.
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%.02f", self.currentTime];
    self.durationLabel.text = [NSString stringWithFormat:@"%.02f", self.duration];
}

@end
