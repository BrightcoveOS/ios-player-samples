# BasicSSAIPlayer (iOS)

Basic Dynamic Delivery SSAI playback: the sample chains a Brightcove SSAI session provider on the FairPlay provider, fetches a video with an ad-config id, and shows a companion ad slot alongside `BCOVPUIPlayerView`. It ships with a runnable demo account, so it plays out of the box.

## Key files

| File | Responsibility |
|---|---|
| `BasicSSAIPlayer/ViewController.swift` | SSAI session provider, content request with the ad-config id, companion slot |
| `BasicSSAIPlayer/AppDelegate.swift` | Configures `AVAudioSession` for playback |

## Optional: Open Measurement

The project links the Open Measurement product for IAB viewability. It is opt-in and off by default. For setup — the OMID partner signature and the VAST 4.1 ad-verification requirements — see the [Brightcove Player SDK for iOS](https://github.com/brightcove/brightcove-player-sdk-ios) documentation.

See the [SSAI README](../) for shared setup.
