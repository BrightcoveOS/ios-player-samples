//
//  ViewController.m
//  SharePlayPlayer
//
//  Created by Jeremy Blaker on 6/29/21.
//

#import "ViewController.h"
#import "SharePlayPlayer-Swift.h"

@import BrightcovePlayerSDK;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L";
static NSString * const kViewControllerAccountID = @"5434391461001";
static NSString * const kViewControllerVideoID = @"6140448705001";

@interface ViewController ()<BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, WatchTogetherWrapperDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, weak) IBOutlet UIButton *playWithSharePlayButton;
@property (nonatomic, weak) IBOutlet UIButton *playLocallyButton;
@property (nonatomic, weak) IBOutlet UIButton *endSharePlayButton;
@property (nonatomic, weak) IBOutlet UILabel *groupSessionLabel;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, strong) BCOVBasicSessionProviderSourceSelectionPolicy sourceSelectionPolicy;
@property (nonatomic, strong) WatchTogetherWrapper *watchTogether;
@property (nonatomic, assign) BOOL playWithSharePlay;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.endSharePlayButton.enabled = NO;
    
    [self playbackControllerSetup];
    [self playerViewSetup];
    
    self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
                                                                policyKey:kViewControllerPlaybackServicePolicyKey];
    
    self.watchTogether = [WatchTogetherWrapper new];
    self.watchTogether.delegate = self;
    self.watchTogether.playbackController = self.playbackController;
    [self.playbackController addSessionConsumer:self.watchTogether];
    
    self.sourceSelectionPolicy = [BCOVBasicSourceSelectionPolicy sourceSelectionHLSWithScheme:@"https"];
}

- (void)playbackControllerSetup
{
    BCOVFPSBrightcoveAuthProxy *authProxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil applicationId:  nil];
    self.playbackController = [BCOVPlayerSDKManager.sharedManager createFairPlayPlaybackControllerWithAuthorizationProxy:authProxy];

    self.playbackController.delegate = self;
    self.playbackController.allowsBackgroundAudioPlayback = YES;
    self.playbackController.autoPlay = NO;
}

- (void)playerViewSetup
{
    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:nil controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout]];
    playerView.playbackController = self.playbackController;
    playerView.delegate = self;

    [self.videoContainerView addSubview:playerView];
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [playerView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
                                              [playerView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor],
                                              [playerView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor],
                                              [playerView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],
                                              ]];
    self.playerView = playerView;
}

- (void)requestContentFromPlaybackService
{
    __weak typeof(self) weakSelf = self;
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (video)
        {
            if (strongSelf.playWithSharePlay)
            {
                NSLog(@"ViewController Debug - Playing video with SharePlay");
                BCOVSource *source = strongSelf.sourceSelectionPolicy(video);
                [strongSelf.watchTogether activateNewActivityWithVideo:video withSource:source];
            }
            else
            {
                NSLog(@"ViewController Debug - Playing video locally");
                [self.playbackController setVideos:@[video]];
            }
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video: `%@`", error);
        }

    }];
}

- (void)updateSessionLabelWithStatus:(NSString *)status
{
    self.groupSessionLabel.text = [NSString stringWithFormat:@"Group Session: %@", status];
}

- (IBAction)playWithSharePlayButtonPressed:(UIButton *)sender
{
    self.playWithSharePlay = YES;
    [self requestContentFromPlaybackService];
}

- (IBAction)playLocallyButtonPressed:(id)sender
{
    // End the existing SharePlay activity if needed
    [self.watchTogether endSharePlay];

    self.playWithSharePlay = NO;
    [self requestContentFromPlaybackService];
}

- (IBAction)endSharePlayButtonPressed:(id)sender
{
    [self.watchTogether endSharePlay];
}

#pragma mark - WatchTogetherWrapperDelegate

- (void)groupSessionWasJoined
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSessionLabelWithStatus:@"Joined"];
        self.endSharePlayButton.enabled = YES;
    });
}

- (void)groupSessionWasInvalidated
{
    NSLog(@"ViewController Debug - Activity was Invalidated");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSessionLabelWithStatus:@"Inactive"];
        self.endSharePlayButton.enabled = NO;
    });
}

- (void)activityWasDisabled
{
    NSLog(@"ViewController Debug - Activity was Disabled or No Activity Active");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSessionLabelWithStatus:@"Inactive"];
        self.endSharePlayButton.enabled = NO;
    });
}

- (void)activityWasActivated
{
    NSLog(@"ViewController Debug - Activity did Activate");
}

- (void)activityFailedActivation
{
    NSLog(@"ViewController Debug - Activity Failed to Activate");
}

@end
