View Strategy Sample
=====================================

`BCOVPlaybackController` objects are constructed with a view strategy, which allows you, as the client of the SDK, to define the exact UIView object that is returned from the playback controller’s view property. 

```
- (void)createPlaybackController
{
    BCOVPlayerSDKManager *sdkManager = BCOVPlayerSDKManager.sharedManager;

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

    self.playbackController = [sdkManager createPlaybackControllerWithViewStrategy:viewStrategy];

    self.playbackController.delegate = self;
    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;

    self.playbackController.view.frame = self.videoContainerView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.videoContainerView addSubview:self.playbackController.view];
}
```

The `BCOVPlaybackControllerViewStrategy` layers the controls view on top of the videoView. This composed view is then passed into the `-[BCOVPlayerSDKManager.sharedManager createPlaybackControllerWithViewStrategy:viewStrategy];`
