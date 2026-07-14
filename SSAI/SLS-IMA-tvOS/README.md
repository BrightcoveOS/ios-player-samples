# SLS-IMA (tvOS)

The tvOS variant (Apple TV only): the same IMA-over-SSAI chain (FairPlay → IMA → SSAI) played through `BCOVTVPlayerView`.

## Key files

| File | Responsibility |
|---|---|
| `SLS_IMA-Player/ViewController.swift` | The FairPlay → IMA → SSAI chain, VMAP tag, tvOS focus handling |
| `SLS_IMA-Player/AppDelegate.swift` | Configures `AVAudioSession` for playback |

Ships with placeholder constants — supply your own account id, policy key, video id, ad-config id, and VMAP ad-tag URL before running. See the [SSAI README](../) for shared setup.
