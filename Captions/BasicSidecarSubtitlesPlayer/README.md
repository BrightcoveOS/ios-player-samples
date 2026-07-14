# Sidecar subtitles (BasicSidecarSubtitlesPlayer)

Adds an external WebVTT subtitle track to an HLS video at runtime — without re-authoring the manifest — using the SidecarSubtitles support built into the core SDK. It chains a Sidecar Subtitles session provider on top of the FairPlay provider, builds an array of subtitle descriptors keyed with `BCOVSSConstants`, and merges them into the `BCOVVideo`'s text-track properties before playback. The SDK then renders the track normally.

## Key files

| File | Responsibility |
|---|---|
| `BasicSidecarSubtitlesPlayer/ViewController.swift` | Sidecar session provider, the text-track descriptor, and content request |

The sample's subtitle text deliberately does not match the video's audio (it is a rendering demonstration). See the [Captions README](../) for shared setup.
