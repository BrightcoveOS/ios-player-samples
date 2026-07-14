# SwiftUI player (SwiftUIPlayer)

Shows three side-by-side ways to bring the same `BCOVPlaybackController` into SwiftUI so you can compare them: a `UIViewControllerRepresentable` around `AVPlayerViewController` (native controls), a `UIViewRepresentable` around `BCOVPUIPlayerView`, and a `UIViewControllerRepresentable` around `BCOVPUIPlayerViewController` (the ads-ready approach). Content is a playlist presented in a `List` / `TabView`, and the model also handles Picture-in-Picture, AirPlay, and fullscreen.

## Key files

| File | Responsibility |
|---|---|
| `SwiftUIPlayer/Models/PlayerModel.swift` | Owns the playback controller and the three player surfaces; PiP / AirPlay / fullscreen |
| `SwiftUIPlayer/Views/ApplePlayerUIView.swift`, `BCOVPlayerUIView.swift`, `BCOVPlayerViewControllerRepresentable.swift` | The three SwiftUI bridges |
| `SwiftUIPlayer/Models/PlaylistModel.swift` | Playlist fetch and list/detail navigation |

See the [Declarative UI README](../) for shared setup.
