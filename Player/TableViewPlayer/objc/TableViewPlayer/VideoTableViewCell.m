//
//  VideoTableViewCell.m
//  TableViewPlayer
//
//  Created by Jeremy Blaker on 6/14/22.
//

#import "VideoTableViewCell.h"
#import "PlaybackConfiguration.h"
#import "Notifications.h"

@import BrightcovePlayerSDK;

@interface VideoTableViewCell ()

@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (nonatomic, weak) IBOutlet UILabel *videoLabel;
@property (nonatomic, weak) IBOutlet UIButton *muteButton;

@property (nonatomic, weak) PlaybackConfiguration *playbackConfiguration;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;

@end

@implementation VideoTableViewCell

#pragma mark - Lifecycle

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.playbackConfiguration.playbackController pause];
    self.playbackConfiguration.playbackSession.player.muted = YES;
    [self updateMuteButton];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Build the BCOVUIPlayerView for this cell
    [self buildPlayerView];
    
    // Handle when another video is unmuted
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unmuteNotificationReceived:) name:VideoDidUnmuteNotification object:nil];
    
    // Handle when the table view stops scrolling
    // We want to play videos in when this happens
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollingStoppedNotificationReceived:) name:ScrollingStoppedNotification object:nil];
    
    // Handle when the table view starts scrolling
    // We want to pause videos when this happens
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollingStartedNotificationReceived:) name:ScrollingStartedNotification object:nil];
}

#pragma mark - Notifications

- (void)unmuteNotificationReceived:(NSNotification *)notification
{
    // Mute all videos except the one for this cell
    UITableViewCell *cell = notification.object;
    if (![cell isEqual:self])
    {
        self.playbackConfiguration.playbackSession.player.muted = YES;
        [self updateMuteButton];
    }
}

- (void)scrollingStoppedNotificationReceived:(NSNotification *)notification
{
    [self.playbackConfiguration.playbackController play];
}

- (void)scrollingStartedNotificationReceived:(NSNotification *)notification
{
    [self.playbackConfiguration.playbackController pause];
}

#pragma mark - Public

- (void)setUpWithVideo:(BCOVVideo *)video playbackConfiguration:(PlaybackConfiguration *)playbackConfiguration
{
    self.playbackConfiguration = playbackConfiguration;
    self.playerView.playbackController = playbackConfiguration.playbackController;
    NSString *videoTitle = video.properties[kBCOVVideoPropertyKeyName];
    self.videoLabel.text = videoTitle;
}

#pragma mark - Private

- (void)buildPlayerView
{
    BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
    
    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout]];
    
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.videoContainer addSubview:playerView];
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
        [playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
        [playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
    ]];
    
    self.playerView = playerView;
}

- (void)updateMuteButton
{
    AVPlayer *player = self.playbackConfiguration.playbackSession.player;
    
    NSString *title = player.isMuted ? @"Unmute" : @"Mute";
    [self.muteButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - IBActions

- (IBAction)toggleVideoMute:(id)sender
{
    AVPlayer *player = self.playbackConfiguration.playbackSession.player;
    
    player.muted = !player.isMuted;
    
    [self updateMuteButton];
    
    if (!player.isMuted)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:VideoDidUnmuteNotification object:self];
    }
}

@end
