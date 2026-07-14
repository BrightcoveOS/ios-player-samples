# IMA ads — iOS (BasicIMAPlayer)

Demonstrates three Google IMA ad configurations, chosen from a launch menu, each in its own view controller sharing a common base:

- **VMAP (Ad Rules)** — a single VMAP tag describes the full break schedule (`BCOVIMAAdsRequestPolicy.videoPropertiesVMAPAdTagUrl()`).
- **VAST (cue points)** — per-cue-point VAST tags fire pre-, mid-, and post-roll `BCOVCuePoint`s.
- **VAST + OMID** — VAST with IAB Open Measurement, registering `IMAFriendlyObstruction`s over the player chrome on each ad sequence.

The shared base builds the FairPlay → IMA session-provider chain, a 300×250 companion ad slot, and the App Tracking Transparency prompt.

## Key files

| File | Responsibility |
|---|---|
| `BasicIMAPlayer/BaseViewController.swift` | Shared player / IMA / FairPlay setup, delegates, companion slot, ATT |
| `BasicIMAPlayer/VMAPViewController.swift`, `VASTViewController.swift`, `VASTOMViewController.swift` | The three ad-configuration variants |
| `BasicIMAPlayer/BCOVVideo+Helpers.swift` | Ad-tag URL constants and cue-point builders |

This sample is localized in eight languages. See the [IMA README](../) for shared setup.
