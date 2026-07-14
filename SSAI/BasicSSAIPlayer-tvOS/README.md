# BasicSSAIPlayer (tvOS)

Basic Dynamic Delivery SSAI playback on tvOS: chains a Brightcove SSAI session provider on the FairPlay provider and plays through `BCOVTVPlayerView`. Ships with a runnable demo account, so it plays out of the box. (Companion slots and the optional Open Measurement / PAL integrations are shown in the iOS sibling.)

## Key files

| File | Responsibility |
|---|---|
| `BasicSSAIPlayer/ViewController.swift` | tvOS player view, SSAI session provider, content request with the ad-config id |
| `BasicSSAIPlayer/AppDelegate.swift` | Configures `AVAudioSession` for playback |

See the [SSAI README](../) for shared setup.
