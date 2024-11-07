View Strategy Sample
=====================================

`BCOVPlaybackController` objects are constructed with a view strategy, which allows you, as the client of the SDK, to define the exact UIView object that is returned from the playback controller’s view property. 

```
func createPlaybackController(){
    let sdkManager = BCOVPlayerSDKManager.sharedManager()

    let viewStrategy  = { (videoView: UIView? , playbackController: BCOVPlaybackController) in {
        let myControlsView = MyControlsView()
        let controlsAndVideoView = UIView()
        videoView.frame = controlsAndVideoView.bounds
        controlsAndVideoView.addSubview(videoView)
        controlsAndVideoView.addSubview(myControlsView)
        playbackController.addSessionConsumer(myControlsView)
        
        // This container view will become `playbackController.view`.
        return controlsAndVideoView
    }

    playbackController = sdkManager.createPlaybackController(withViewStrategy: viewStrategy)

    playbackController.delegate = self
    playbackController.autoPlay = true
    playbackController.autoAdvance = true

    playbackController.view.frame = videoContainerView.bounds
    playbackController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    videoContainerView.addSubview(playbackController.view)
}
```

The `BCOVPlaybackControllerViewStrategy` layers the controls view on top of the videoView. This composed view is then passed into the `BCOVPlayerSDKManager.sharedManager().createPlaybackController(withViewStrategy: viewStrategy)`
