# IMA ads — tvOS (NativeControlsIMAPlayer)

Plays a VMAP-scheduled IMA ad break inside Apple's native `AVPlayerViewController` transport controls on tvOS. It sets `kBCOVAVPlayerViewControllerCompatibilityKey` to avoid a duplicate `AVPlayerLayer`, toggles `showsPlaybackControls` off and on across the ad sequence, and populates the tvOS Info panel with external metadata.

## Requirements

- tvOS 15.0+ (this sample is Apple TV only)

## Key files

| File | Responsibility |
|---|---|
| `NativeControlsIMAPlayer/ViewController.swift` | The whole sample — IMA session provider, native-controls integration, VMAP tag, metadata, ATT |

See the [IMA README](../) for shared setup.
