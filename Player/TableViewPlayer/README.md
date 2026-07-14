# Video list / playlist (TableViewPlayer)

Plays many videos in a `UITableView` — one `BCOVPlaybackController` per cell, loaded from a playlist. It shows how to run multiple players at once without exhausting resources: buffer optimization (`kBCOVBufferOptimizerMethodKey` with a 1–5 s window), scroll-driven play/pause, and per-cell mute coordination. Live videos are dropped as they advance.

## Key files

| File | Responsibility |
|---|---|
| `TableViewPlayer/ViewController.swift` | Playlist fetch, per-video controllers, buffer tuning, scroll notifications |
| `TableViewPlayer/VideoTableViewCell.swift` | Per-cell player view, mute logic, scroll observers, reuse handling |

See the [Playback README](../) for shared setup.
