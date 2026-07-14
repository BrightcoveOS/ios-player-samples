# SLS-IMA (iOS)

Layers client-side Google IMA ads (a VMAP tag) on top of SSAI — the FairPlay → IMA → SSAI provider chain — for a Server-Side Live + IMA workflow. Plays through `BCOVPUIPlayerView`.

## Key files

| File | Responsibility |
|---|---|
| `SLS_IMA-Player/ViewController.swift` | The FairPlay → IMA → SSAI chain, VMAP tag, IMA delegates |
| `SLS_IMA-Player/AppDelegate.swift` | Configures `AVAudioSession` for playback |

Ships with placeholder constants — supply your own account id, policy key, video id, ad-config id, and VMAP ad-tag URL before running. See the [SSAI README](../) for shared setup.
