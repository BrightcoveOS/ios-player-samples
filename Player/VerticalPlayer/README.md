# Vertical video (VerticalPlayer)

A full-bleed vertical (TikTok-style) paging feed built on `UIPageViewController` with wraparound paging through a playlist. Each page is its own `BCOVPlaybackController` with `videoGravity = .resizeAspectFill`; a poster image fades out once playback is likely to keep up, a tap toggles play/pause, and a share sheet is built from the video's name and poster.

## Key files

| File | Responsibility |
|---|---|
| `VerticalPlayer/BCOVPageViewController.swift` | Playback service, playlist, wraparound paging data source, credential constants |
| `VerticalPlayer/VideoViewController.swift` | Per-video playback, poster, gestures, share, lifecycle |

See the [Playback README](../) for shared setup.
