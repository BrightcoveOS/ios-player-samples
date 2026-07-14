# Native controls (NativeControls)

Plays Video Cloud content through Apple's native `AVPlayerViewController` transport controls instead of the Brightcove `BCOVPUIPlayerView`. The key is `kBCOVAVPlayerViewControllerCompatibilityKey` on the playback controller options — this stops the SDK from creating a redundant `AVPlayerLayer` — after which the session's `AVPlayer` is handed to the AVKit controller as each session advances.

## Key files

| File | Responsibility |
|---|---|
| `NativeControls/ViewController.swift` | Hosts `AVPlayerViewController`, sets the compatibility option, wires the player on session advance |

See the [Playback README](../) for shared setup.
