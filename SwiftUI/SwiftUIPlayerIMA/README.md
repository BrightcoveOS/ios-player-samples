# SwiftUIPlayerIMA

Reference sample showing how to integrate the **Brightcove Native Player SDK for iOS** with **Google Interactive Media Ads (IMA)** in a **SwiftUI** app.

The launch screen lets the user pick one of three ad delivery modes; tapping **Start** opens the player, where the same playback controller can swap between two demo videos.

- **VMAP** — single tag URL describes the full ad break schedule (server-side rules).
- **VAST** — per-cuepoint tags trigger pre-roll, mid-roll, and post-roll on the client.
- **VAST + OMID** — VAST with Open Measurement (IAB viewability) and friendly-obstruction registration over the player chrome.

The mode is locked for the player session. To play with a different mode, navigate back to the configuration screen — that tears the player view controller down so a fresh IMA chain is built for the new mode. The same is true of any real production app: pick one ad strategy and stick to it.

## Requirements

- iOS 17.0+
- Xcode 16+

## Setup

Open `SwiftUIPlayerIMA.xcodeproj` in Xcode. Swift Package Manager resolves the Brightcove SDK and the Google Interactive Media Ads package automatically on the first build.

## Architecture

Ten files do the work:

| File | Responsibility |
|---|---|
| `SwiftUIPlayerIMAApp.swift` | `@main` entry, hosts the root `NavigationStack` |
| `AppDelegate.swift` | Configures `AVAudioSession` for video playback |
| `Config.swift` | Brightcove account, demo videos, ad-tag constants, and `AdMode` enum |
| `Logging.swift` | `os_log` namespace (`Log.session`, `Log.playback`, `Log.ads`, `Log.lifecycle`) |
| `BCOVVideo+IMA.swift` | Helpers to attach a VMAP tag or VAST cuepoints to a `BCOVVideo` |
| `Models/PlayerViewModel.swift` | `@MainActor @Observable` view model. Locked to one ad mode at construction. Owns the playback controller (strong) and the companion-ad UIView; conforms to the Brightcove and IMA delegates |
| `Views/ConfigurationView.swift` | Root screen: ad-mode picker + Start `NavigationLink` |
| `Views/PlayerView.swift` | Player screen: 16:9 player + playlist (two videos) + status row + fullscreen toggle + companion-ad slot |
| `Views/BCOVPlayerRepresentable.swift` | `UIViewControllerRepresentable` bridging the player view controller to SwiftUI |
| `Views/IMAPlayerViewController.swift` | `BCOVPUIPlayerViewController` subclass that wires the **FairPlay → IMA → playback controller** chain in `viewDidLoad`, including companion slot and OMID friendly-obstruction registration |

### Why subclass `BCOVPUIPlayerViewController`?

Google IMA's ad UI requires a real `UIViewController` ancestor. The Brightcove SDK's `BCOVPUIPlayerViewController` is purpose-built as the SwiftUI host: its header doc-comment explicitly says _"For SwiftUI apps, wrap this view controller in a `UIViewControllerRepresentable`."_ Subclassing lets us build the IMA chain in `viewDidLoad`, after the view hierarchy is in place but before the player attempts to play any video.

### Switching videos

Inside the player screen, the user picks between two demo videos. Both are loaded into the **same** playback controller via `setVideos([newVideo])` — the IMA chain stays wired, the same ad policy applies to both. This is the canonical SDK pattern for "watch next" / autoplay flows.

### Switching ad modes

Ad mode is set at `PlayerViewModel` construction and never changes during a session. Going back from the player screen to the configuration screen tears down the player VC; tapping **Start** again with a different mode builds a fresh IMA chain.

## Diagnostic logging

All Brightcove lifecycle events, all IMA ad events, and all delegate callbacks are emitted to Apple's Unified Logging under the `com.brightcove.SwiftUIPlayerIMA` subsystem. Stream from the command line:

```sh
log stream --predicate 'subsystem == "com.brightcove.SwiftUIPlayerIMA"' --info
```

Filter to a category (`session`, `playback`, `ads`, `lifecycle`):

```sh
log stream --predicate 'subsystem == "com.brightcove.SwiftUIPlayerIMA" AND category == "ads"' --info
```

Or in Xcode: open the Console pane and filter on the subsystem.

The UI deliberately does not surface this output — the sample is a documentation reference first; logs are for diagnosis when something goes wrong.

## Manual smoke test

After building and launching, exercise these paths and watch the log stream:

1. **Pre-roll plays** — pick a mode, tap **Start**, wait for `Ad event: Started` → `First Quartile` → `Midpoint` → `Third Quartile` → `Complete` → `Exiting ad sequence`.
2. **Switch videos mid-session** — once content is playing, tap the second video in the **Now playing** list. The same playback controller loads the new asset; ads apply per the locked mode.
3. **Switch ad modes** — go back to the configuration screen, pick a different mode, tap **Start**. A fresh IMA chain is built; pre-roll fires under the new policy.
4. **In-app browser** — tap "Learn More" on a pre-roll. The browser opens, then closing it logs `In-app browser closed; resuming ad` and the ad resumes.
5. **OMID friendly obstruction** — pick `VAST+OMID`; on the next ad sequence, expect `Registered OMID friendly obstruction over player overlay` in the log.

## Security

`Info.plist` sets `NSAllowsArbitraryLoads = true` so Google's IMA test ad
creatives can be fetched over a mix of HTTP and HTTPS endpoints. This is a
sample-only convenience. Production apps should remove the global allow-list
and instead use `NSAllowsArbitraryLoadsForMedia` (relaxed for media URLs only)
or per-domain `NSExceptionDomains` entries scoped to the specific ad-server
hosts the app integrates with.

## See also

- `IMA/BasicIMAPlayer-iOS/` — the canonical UIKit IMA sample (VAST, VMAP, and VAST+OMID variants).
- `SwiftUI/SwiftUIPlayer/` — SwiftUI without ads, demonstrating multiple bridge approaches.
