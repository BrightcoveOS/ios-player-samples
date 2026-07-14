# 360° video (Video360)

Retrieves and plays a 360°/VR video. Retrieval and playback are the same as for any Video Cloud video; what's specific is handling the `BCOVPUIPlayerViewDelegate` 360-navigation callback to switch device orientation when the viewer enters VR-goggles mode.

## Key files

| File | Responsibility |
|---|---|
| `Video360Player/ViewController.swift` | 360 navigation-method delegate and orientation handling |

See the [Playback README](../) for shared setup.
