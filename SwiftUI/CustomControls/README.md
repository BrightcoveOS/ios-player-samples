# Custom controls — SwiftUI (CustomControls)

SwiftUI custom controls driven by an `ObservableObject` that observes `BCOVPlaybackController` delegate callbacks (progress, duration, buffered range). The SDK video view is bridged in with a `UIViewRepresentable`, and a WebVTT thumbnail preview is shown while scrubbing.

## Key files

| File | Responsibility |
|---|---|
| `CustomControls/Models/PlayerModel.swift` | Playback controller + delegate → published UI state |
| `CustomControls/Views/PlayerUIView.swift` | Composition, video load, thumbnail wiring |
| `CustomControls/Views/VideoContainerView.swift` | `UIViewRepresentable` bridge for the SDK video view |
| `CustomControls/Views/CustomControlsView.swift` | The SwiftUI control bar and scrubber |

For UIKit custom controls, see [`PlayerUI/CustomControls`](../../PlayerUI/CustomControls/). See the [Declarative UI README](../) for shared setup.
