# Basic playback (VideoCloudBasicPlayer)

The reference basic player: it fetches a single video from Video Cloud with `BCOVPlaybackService.findVideo` and plays it in a `BCOVPUIPlayerView`. It also doubles as the reference for several playback features layered on top:

- **AirPlay** — enabling external playback and toggling route detection.
- **Background audio** — the `AVAudioSession` category plus a mute toggle.
- **Picture-in-Picture** — the PiP delegate callbacks.
- **Lock-screen / Now Playing** — `MPRemoteCommandCenter` commands and `MPNowPlayingInfoCenter` metadata.
- **Audio-only assets** — Now Playing info built from `album_name` / `album_artist` custom fields (a commented-out audio-only video id is provided).

## Key files

| File | Responsibility |
|---|---|
| `VideoCloudBasicPlayer/ViewController.swift` | Player view, AirPlay route detector, PiP delegates, audio session and mute |
| `VideoCloudBasicPlayer/NowPlayingHandler.swift` | Remote-command center, Now Playing info, artwork, audio-only handling |

See the [Playback README](../) for shared setup and requirements.
