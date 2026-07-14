# IMA ads — SwiftUI (SwiftUIPlayerIMA)

Integrates Google IMA ads into a SwiftUI player. A launch screen picks one of three ad modes — VMAP, VAST cue points, or VAST + Open Measurement (OMID) — and the player builds the FairPlay → IMA chain for the chosen mode in a `BCOVPUIPlayerViewController` subclass bridged into SwiftUI. The ad mode is locked for the session; going back to the configuration screen rebuilds the chain for a different mode.

## Key files

| File | Responsibility |
|---|---|
| `SwiftUIPlayerIMA/Views/IMAPlayerViewController.swift` | Wires the FairPlay → IMA chain, companion slot, and OMID obstruction |
| `SwiftUIPlayerIMA/Models/PlayerViewModel.swift` | The observable view model and its Brightcove/IMA delegate conformances |
| `SwiftUIPlayerIMA/BCOVVideo+IMA.swift` | VMAP / VAST cue-point helpers |
| `SwiftUIPlayerIMA/Config.swift` | Account, demo videos, ad-tag URLs, and the ad-mode enum |

> **Note:** `Info.plist` enables arbitrary loads so Google's test ad creatives load over mixed HTTP/HTTPS — a sample-only convenience. Production apps should scope this to the specific ad-server hosts instead.

See the [Declarative UI README](../) for shared setup, and [`IMA/`](../../IMA/) for the UIKit IMA samples.
