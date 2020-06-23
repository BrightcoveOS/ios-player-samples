View Strategy Sample
=====================================

`BCOVPlaybackController` objects are constructed with a view strategy, which allows you, as the client of the SDK, to define the exact UIView object that is returned from the playback controller’s view property. 

```
- (void)createPlaybackController
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    BCOVPlaybackControllerViewStrategy viewStrategy = ^UIView *(UIView *videoView, id<BCOVPlaybackController> playbackController)
    {
        UIViewBCOVPlaybackSessionConsumer *myControlsView = [[MyControlsView alloc] init];
        UIView *controlsAndVideoView = [[UIView alloc] init];
        videoView.frame = controlsAndVideoView.bounds;
        [controlsAndVideoView addSubview:videoView];
        [controlsAndVideoView addSubview:myControlsView];
        [playbackController addSessionConsumer:myControlsView];
        
        // This container view will become `playbackController.view`.
        return controlsAndVideoView;
    };

    self.playbackController = [manager createPlaybackControllerWithViewStrategy:viewStrategy];

    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    self.playbackController.delegate = self;

    self.playbackController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
    [self.videoContainer addSubview:self.playbackController.view];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.playbackController.view.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
        [self.playbackController.view.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
        [self.playbackController.view.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
        [self.playbackController.view.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
    ]];
}
```

The `BCOVPlaybackControllerViewStrategy` layers the controls view on top of the videoView. This composed view is then passed into the `-[BCOVSDKManager createPlaybackControllerWithViewStrategy:viewStrategy];`
