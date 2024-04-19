//
//  VideoTableViewCell.m
//  TableViewPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "Notifications.h"
#import "PlaybackConfiguration.h"

#import "VideoTableViewCell.h"


@interface VideoTableViewCell ()

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
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

    self.playerView = ({
        BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
        BCOVPUIBasicControlView *controlsView = BCOVPUIBasicControlView.basicControlViewWithVODLayout;

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.tag == %@", @(BCOVPUIViewTagButtonScreenMode)];
        BCOVPUILayoutView *screenModeButton = [controlsView.layout.allLayoutItems.allObjects filteredArrayUsingPredicate:predicate].firstObject;
        screenModeButton.removed = YES;

        BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc]
                                         initWithPlaybackController:nil
                                         options:options
                                         controlsView:controlsView];

        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        playerView.frame = self.videoContainerView.bounds;
        [self.videoContainerView addSubview:playerView];

        playerView;
    });

    // Handle when another video is unmuted
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(unmuteNotificationReceived:)
                                               name:VideoDidUnmuteNotification
                                             object:nil];

    // Handle when the table view stops scrolling
    // We want to play videos in when this happens
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(scrollingStoppedNotificationReceived:)
                                               name:ScrollingStoppedNotification object:nil];

    // Handle when the table view starts scrolling
    // We want to pause videos when this happens
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(scrollingStartedNotificationReceived:)
                                               name:ScrollingStartedNotification
                                             object:nil];
}


- (void)setUpWithVideo:(BCOVVideo *)video
 playbackConfiguration:(PlaybackConfiguration *)playbackConfiguration
{
    self.playbackConfiguration = playbackConfiguration;
    self.playerView.playbackController = playbackConfiguration.playbackController;
    self.videoLabel.text = video.properties[kBCOVVideoPropertyKeyName];
}

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

- (void)updateMuteButton
{
    AVPlayer *player = self.playbackConfiguration.playbackSession.player;

    NSString *title = player.isMuted ? @"Unmute" : @"Mute";
    [self.muteButton setTitle:title
                     forState:UIControlStateNormal];
}

- (void)scrollingStoppedNotificationReceived:(NSNotification *)notification
{
    [self.playbackConfiguration.playbackController play];
}

- (void)scrollingStartedNotificationReceived:(NSNotification *)notification
{
    [self.playbackConfiguration.playbackController pause];
}

- (IBAction)toggleVideoMute:(id)sender
{
    AVPlayer *player = self.playbackConfiguration.playbackSession.player;

    player.muted = !player.isMuted;

    [self updateMuteButton];

    if (!player.isMuted)
    {
        [NSNotificationCenter.defaultCenter postNotificationName:VideoDidUnmuteNotification
                                                          object:self];
    }
}

@end
