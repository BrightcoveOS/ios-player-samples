# Basic playback — tvOS (AppleTV)

The tvOS player (Apple TV only). It plays a single video with `BCOVTVPlayerView` and adds a custom info panel to the player's overlay.

## Key files

| File | Responsibility |
|---|---|
| `AppleTV/ViewController.swift` | tvOS player view, FairPlay session provider, video fetch, focus handling |
| `AppleTV/SampleInfoViewController.swift` | Custom info-view controller injected into the player overlay |

See the [Playback README](../) for shared setup.
