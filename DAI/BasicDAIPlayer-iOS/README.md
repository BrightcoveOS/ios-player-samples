# BasicDAIPlayer (iOS)

Google Dynamic Ad Insertion on iOS. A launch menu picks one of two stream-request policies — Video Properties (source-id + video-id, VOD) and Asset Key (live) — both played through `BCOVPUIPlayerView`.

## Key files

| File | Responsibility |
|---|---|
| `BasicDAIPlayer/BaseViewController.swift` | Shared DAI + FairPlay setup and delegates |
| `BasicDAIPlayer/VideoPropertiesViewController.swift` | The Video Properties (VOD) policy |
| `BasicDAIPlayer/AssetKeyViewController.swift` | The Asset Key (live) policy |

See the [DAI README](../) for shared setup.
