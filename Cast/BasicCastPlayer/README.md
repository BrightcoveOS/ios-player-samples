# Casting — default receiver (BasicCastPlayer)

Casts to the **default Google media receiver** using Brightcove's `BCOVGoogleCastManager`, added to the playback controller with `playbackController.add(googleCastManager)`. The sample also ships a fully custom `GoogleCastManager` (a `BCOVPlaybackSessionConsumer`) — commented out — that you can swap in when you need behavior the plugin does not cover, such as custom source selection or media-info construction.

The default receiver does **not** support DRM or ads and only handles `HLSv3`, `DASH`, and `MP4`. For DRM, SSAI, and HLSv3-or-superior, use [`BrightcoveCastReceiver`](../BrightcoveCastReceiver/).

## Key files

| File | Responsibility |
|---|---|
| `BasicCastPlayer/ViewController.swift` | Playlist UI, cast button, `BCOVGoogleCastManager` wiring |
| `BasicCastPlayer/GoogleCastManager.swift` | The optional custom cast manager (source filtering, media info, session/media delegates) |
| `BasicCastPlayer/AppDelegate.swift` | `GCKCastContext` setup with the default receiver |

See the [Casting README](../) for shared setup.
