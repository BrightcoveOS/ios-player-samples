# Custom subtitle rendering (SubtitleRendering)

Takes full control of subtitle presentation instead of using the built-in caption engine. It hides the CC button, disables AVPlayer's automatic caption selection, then downloads and parses the WebVTT itself and renders each cue in a custom `UILabel` driven by an `AVPlayer` periodic time observer. Available tracks are listed in a table for selection or disabling.

## Key files

| File | Responsibility |
|---|---|
| `SubtitleRendering/ViewController.swift` | Track discovery, selection table, time-observer → label |
| `SubtitleRendering/SubtitleManager.swift` | WebVTT download and parsing, `subtitleForTime(_:)` lookup |

The sample uses a video that carries real text tracks, and logs a warning if the device's "Closed Captions + SDH" accessibility setting is on (which can force a track to render). See the [Captions README](../) for shared setup.
