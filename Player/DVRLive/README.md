# Live / DVR (DVRLive)

Plays a live HLS stream with the live / DVR control layout, building the video from a raw HLS URL rather than the playback service.

## Key files

| File | Responsibility |
|---|---|
| `DVRLive/ViewController.swift` | Live HLS source, the live / DVR control layout, playback |

This sample ships without a live URL — set `kVideoURLString` to your own live HLS stream before running. See the [Playback README](../) for shared setup.
