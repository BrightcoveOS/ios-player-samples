# View strategy (ViewStrategy)

A `BCOVPlaybackController` is constructed with a *view strategy* — a closure that lets you, the client of the SDK, define the exact `UIView` returned from the controller's `view` property. This sample uses it to compose the SDK's video view with a custom controls view into a single container.

```swift
func createPlaybackController() {
    let sdkManager = BCOVPlayerSDKManager.sharedManager()

    let viewStrategy: BCOVPlaybackControllerViewStrategy = { (videoView: UIView?, playbackController: BCOVPlaybackController?) -> UIView? in
        guard let videoView, let playbackController else { return nil }

        let controlsView = ViewStrategyCustomControls(with: playbackController)
        let controlsAndVideoView = UIView()
        controlsAndVideoView.frame = videoView.bounds
        controlsAndVideoView.addSubview(videoView)
        controlsAndVideoView.addSubview(controlsView)
        playbackController.add(controlsView)

        // This container view will become `playbackController.view`.
        return controlsAndVideoView
    }

    playbackController = sdkManager.createPlaybackController(withViewStrategy: viewStrategy)

    playbackController.delegate = self
    playbackController.isAutoPlay = true
    playbackController.isAutoAdvance = true

    playbackController.view.frame = videoContainerView.bounds
    playbackController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    videoContainerView.addSubview(playbackController.view)
}
```

The closure layers the controls view over the video view and registers it as a session consumer with `playbackController.add(...)`; the composed container becomes `playbackController.view`.

## Key files

| File | Responsibility |
|---|---|
| `ViewStrategy/ViewController.swift` | Defines and uses the view-strategy closure |
| `ViewStrategy/ViewStrategyCustomControls.swift` | The composed custom-controls `UIView` |

See the [UI Customization README](../) for shared setup.
