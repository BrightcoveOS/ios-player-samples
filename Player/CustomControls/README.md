Custom Controls Sample
=====================================
### Fullscreen Button

This sample doesn't utilize a view stategy. If you need to use plugin like IMA that uses a view strategy. You could do the following:

```
- (void)setup
{
    _videoView = [[UIView alloc] init];
    _fullscreenViewController = [[UIViewController alloc] init];
    
    _controlsViewController = [[ControlsViewController alloc] init];
    _controlsViewController.delegate = self;

    ViewController * __weak weakSelf = self;

    BCOVPlaybackControllerViewStrategy viewStrategy = ^ UIView *(UIView *videoView, id<BCOVPlaybackController> playbackController) {

        ViewController *strongSelf = weakSelf;
        UIView *view = [[UIView alloc] initWithFrame:videoView.bounds];
        videoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [view addSubview:videoView];
        strongSelf.controlsViewController.view.frame = view.bounds;
        strongSelf.controlsViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [view addSubview:strongSelf.controlsViewController.view];

        return view;
        
    };

    _playbackController = [[BCOVPlayerSDKManager sharedManager] createPlaybackControllerWithViewStrategy:[[BCOVPlayerSDKManager sharedManager] IMAAdViewStrategyWrapperWithViewStrategey:viewStrategy];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;
    [_playbackController setAllowsExternalPlayback:YES];
    [_playbackController addSessionConsumer:_controlsViewController];

    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        // Do any additional setup after loading the view, typically from a nib.

    self.playbackController.view.frame = self.videoView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoView addSubview:self.playbackController.view];

    self.videoView.frame = self.videoContainer.bounds;
    self.videoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer addSubview:self.videoView];

    [self addChildViewController:self.controlsViewController];

    [self requestContentFromCatalog];
}
```

The `BCOVPlaybackControllerViewStrategy` layers the controls view on top of the videoView. This composed view is then passed into the `-[BCOVSDKManager IMAAdViewStrategyWrapperWithViewStrategey:viewStrategy];
