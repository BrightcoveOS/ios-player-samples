//
//  ViewController.m
//  BasicOUXtvOSPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveOUX;


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

// currentSession is weak so that it can be released properly
@property (nonatomic, weak) id<BCOVPlaybackSession> currentSession;
@property (nonatomic) BCOVTVPlayerView *playerView;

@property (nonatomic) NSTimeInterval currentTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) BOOL playingAdSequence;
@property (nonatomic) UIView *topDrawerView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createPlayerView];
    [self createPlaybackController];
}

- (void)createPlayerView
{
    if (self.playerView == nil)
    {
        [self loadViewIfNeeded];
        
        BCOVTVPlayerViewOptions *options = [[BCOVTVPlayerViewOptions alloc] init];
        options.presentingViewController = self;
        //options.hideControlsInterval = 3000;
        //options.hideControlsAnimationDuration = 0.2;
        
        self.playerView = [[BCOVTVPlayerView alloc] initWithOptions:options];
        
        NSAssert(self.videoContainer != nil, @"Video container hasn't loaded yet");
        [self.videoContainer addSubview:self.playerView];
        
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
                                                  [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
                                                  [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
                                                  [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
                                                ]];
    }
}

- (void)createPlaybackController
{
    if (!self.playbackController)
    {
        NSLog(@"Creating a new playbackController");
        self.playbackController = [[BCOVPlayerSDKManager sharedManager] createOUXPlaybackControllerWithViewStrategy:nil];
        self.playbackController.delegate = self;
        self.playbackController.autoAdvance = YES;
        self.playbackController.autoPlay = YES;
        self.playerView.playbackController = self.playbackController;
        NSLog(@"Created a new playbackController");
        
        // Create video
        BCOVVideo *video = [self createOUXVideoObject];
        [self.playbackController setVideos:@[video]];
    }
    else
    {
        NSLog(@"The playbackController already exists, ignoring the call to create it.");
    }
}

// Create a BCOVVideo from the OnceUX source.
- (BCOVVideo *)createOUXVideoObject
{
    // Sample Once URL
    static NSString *kViewControllerVideoURLString = @"http://once.unicornmedia.com/now/ads/vmap/od/auto/c501c3ee-7f1c-4020-aa6d-0b1ef0bbd4a9/354a749c-217b-498e-b4f9-c48cd131f807/66496c0e-6969-41b1-859f-9bdf288cfdd3/content.once";
    NSURL *url = [NSURL URLWithString:kViewControllerVideoURLString];
    // set the delivery method
    BCOVSource *source = [[BCOVSource alloc] initWithURL:url deliveryMethod:kBCOVSourceDeliveryHLS properties:nil];
    // fill out properties for the Info Panel display
    return [[BCOVVideo alloc] initWithSource:source cuePoints:[BCOVCuePointCollection collectionWithArray:@[]]
                                  properties:@{@"name":@"Sintel",
                                               @"thumbnail":@"https://solutions.brightcove.com/bsahlas/assets/title-Sintel.jpg",
                                               @"duration":@"90000",
                                               @"long_description":@"\"Sintel\" is an independently produced short film, initiated by the Blender Foundation as a means to further improve andvalidate the free/open source 3D creation suite Blender. With initial funding provided by 1000s of donations via the internet community, it has again proven to be a viable development model for both open 3D technology as for independent animation film. This 15 minute film has been realized in the studio of the Amsterdam Blender Institute, by an international team of artists and developers. In addition to that, several crucial technical and creative targets have been realized online, by developers and artists and teams all over the world."
                                               @"\n\n"
                                               @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean eleifend fringilla nisi, sed commodo massa varius vitae. Mauris ut augue consequat, interdum nunc sed, viverra mauris. Sed eget imperdiet diam. Mauris volutpat porta elementum. Nulla ut massa ante. Duis et tellus ultricies, vestibulum erat viverra, venenatis libero. Duis feugiat et ligula eu interdum. Quisque pretium a quam quis pellentesque. Nulla vestibulum efficitur ex, sit amet luctus elit scelerisque id. Nam ut dolor tempus, sollicitudin quam quis, placerat nunc. Quisque ipsum magna, facilisis non viverra non, aliquam ut arcu.\n\nNulla dapibus sapien sit amet molestie fermentum. Aenean rhoncus hendrerit lorem vel volutpat. Sed ultrices euismod dui, ut rutrum elit cursus et. Nullam dictum sollicitudin dolor, et efficitur erat. Phasellus eleifend finibus odio eu fermentum. Mauris vehicula metus odio, et viverra velit aliquam id. Donec ornare est magna, id feugiat elit blandit et. Curabitur sodales justo quis varius dignissim.\n\nVivamus vitae magna id augue condimentum bibendum. Integer sit amet convallis odio, quis molestie metus. Sed ac lacus quis sem sodales euismod. Suspendisse quis hendrerit quam, nec pellentesque elit. Fusce pellentesque ultricies enim, in sodales dolor sollicitudin iaculis. Pellentesque mattis lobortis dignissim. In interdum diam in mattis mollis. Donec blandit enim quis odio varius vestibulum. Suspendisse erat ex, pharetra at urna ut, ullamcorper facilisis nunc. Fusce aliquet lorem eget arcu convallis elementum. Fusce vehicula gravida nisl et consequat. Curabitur aliquet luctus tellus eu condimentum. Phasellus vel eros ac velit condimentum consectetur. Proin lorem eros, venenatis eget cursus ut, tincidunt ac ligula"
                                               }];
}

#pragma mark - UIFocusEnvironment protol methods

// Preferred focus for tvOS 9
- (UIView *)preferredFocusedView
{
    return self.playerView;
}

// Preferred focus for tvOS 10+
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return (@[ self.playerView.controlsView ?: self ]);
}

#pragma mark - Playback Controller delegate methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.currentSession = session;
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

- (void)playbackController:(id<BCOVPlaybackController>)controller didCompletePlaylist:(id<NSFastEnumeration>)playlist
{
    NSLog(@"ViewController Debug - Playlist complete; replaying video");
    [self.playbackController setVideos:playlist];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"ViewController Debug - lifecycle event type: %@", lifecycleEvent.eventType);
}

@end
