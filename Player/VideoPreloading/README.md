# Video preloading (VideoPreloading)

Demonstrates seamless advance between videos with double buffering: two `BCOVPlaybackController`s share a single `BCOVPUIPlayerView`, and the "next" controller preloads the upcoming video while the current one plays. Preloading is triggered once the current video passes a 75% progress threshold; auto-advance is off, so the manager swaps controllers on the playback-end event. The playlist is fetched by reference id.

## Key files

| File | Responsibility |
|---|---|
| `VideoPreloading/ViewController.swift` | Player view, playlist-by-reference-id fetch, progress/end delegate wiring |
| `VideoPreloading/VideoPreloadManager.swift` | The two controllers, the 75% threshold, and the swap logic |

See the [Playback README](../) for shared setup.
