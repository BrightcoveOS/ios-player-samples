# SwiftUI player (SwiftUIPlayer)

Shows three side-by-side ways to bring the same `BCOVPlaybackController` into SwiftUI, so you can compare them:

- `ApplePlayerUIView` — a `UIViewControllerRepresentable` around `AVPlayerViewController` (native Apple controls), using `kBCOVAVPlayerViewControllerCompatibilityKey`.
- `BCOVPlayerUIView` — a `UIViewRepresentable` around `BCOVPUIPlayerView`.
- `BCOVPlayerViewControllerRepresentable` — a `UIViewControllerRepresentable` around `BCOVPUIPlayerViewController`, the approach documented as ads-ready.

Content is a playlist fetched by reference id and presented in a `List` / `TabView`; the model also handles Picture-in-Picture, AirPlay, and fullscreen.

## Requirements

- iOS 16.0+

## Key files

| File | Responsibility |
|---|---|
| `SwiftUIPlayer/Models/PlayerModel.swift` | Owns the playback controller and the three player surfaces; PiP / AirPlay / fullscreen delegates |
| `SwiftUIPlayer/Views/ApplePlayerUIView.swift`, `BCOVPlayerUIView.swift`, `BCOVPlayerViewControllerRepresentable.swift` | The three SwiftUI bridges |
| `SwiftUIPlayer/Models/PlaylistModel.swift`, `Views/VideoListView.swift` | Playlist fetch and list/detail navigation |

See the [Declarative UI README](../) for shared setup.
