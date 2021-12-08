# flutter_bcov

The *flutter_bcov* package contains two auxiliar classes and one widget to [display video](https://docs.flutter.dev/development/platform-integration/platform-views).

## How to use flutter_bcov

### PlaybackController

The *PlaybackController* class determines the behavior of your playback controller for autoAdvance and autoPlay. The default values for both is false.

```dart
    PlaybackController(
        autoPlay: true,
        autoAdvance: true,
    );
```

### PlaybackService

The *PlaybackService* class is used to retrieve the video to be shown in your playback controller. The *accountId* and *videoId* are the only required values. The *policyKey*, *authToken* and *parameters* are optional values.

```dart
    PlaybackService(
        accountId: '5434391461001',
        policyKey: 'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L',
        videoId: '6140448705001',
    );
```

### BCOVVideoPlayer

The *BCOVVideoPlayer* class is the widget to be used to show the video. The class receives two paramters, *playbackController* and *playbackService*.

```dart
    BCOVVideoPlayer(
        playbackController: PlaybackController(
            autoPlay: true,
            autoAdvance: true,
        ),
        playbackService: PlaybackService(
            accountId: '5434391461001',
            policyKey: 'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L',
            videoId: '6140448705001',
        ),
    );
```
