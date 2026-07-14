# flutter_bcov

`flutter_bcov` is the Flutter (Dart) side of the [`Flutter`](../) sample. It hosts the native Brightcove player as a [platform view](https://docs.flutter.dev/development/platform-integration/platform-views) and overlays Flutter-drawn controls on top of it.

## Structure

| File | Responsibility |
|---|---|
| `lib/main.dart` | Module entry point; provides a `BCOVViewModel` and shows `BCOVVideoPlayer` |
| `lib/src/player_controller.dart` | The `BCOVVideoPlayer` widget — binds the view model to the player view |
| `lib/src/player_view_widget.dart` | `PlayerView` — embeds the native player via `UiKitView` (`viewType: 'bcov.flutter/player_view'`) and overlays the controls |
| `lib/src/controls_widget.dart` | `BCOVControls` — the Flutter play/pause button, seek bar, and thumbnail preview |
| `lib/src/viewmodel.dart` | `BCOVViewModel` — bridges to the native player over the method/event channels |

## How it talks to the native player

`BCOVViewModel` communicates with the native `BCOVVideoPlayer` (in `Flutter/FlutterPlayer/`) over two channels:

- **Method channel** `bcov.flutter/method_channel` (Dart → native): `playPause`, `seek`, `thumbnailAtTime`.
- **Event channel** `bcov.flutter/event_channel` (native → Dart): `didAdvanceToPlaybackSession`, `didProgressTo`, `eventEnd`, and ad-sequence enter/exit — the view model maps these onto its `isPlaying` / `currentTime` / `totalTime` / `inAdSequence` state to drive the controls.

The account, policy key, and video id are set on the **native** side (`Flutter/FlutterPlayer/BCOVVideoPlayer.swift`), not in Dart. To build and run the sample, follow the setup in the [`Flutter` README](../).
