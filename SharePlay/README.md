# Co-watching (SharePlay)

The `SharePlay` bucket demonstrates synchronizing Brightcove playback across the participants of a FaceTime call using Apple's [GroupActivities](https://developer.apple.com/documentation/groupactivities) framework. It is **iOS only** — SharePlay and its `AVPlayerPlaybackCoordinator` bridge are Apple platform APIs with no tvOS equivalent here.

The single sample, **SharePlayPlayer**, lets the user start a shared session, play locally, or end the session, keeping playback position in sync for everyone in the call.

## Requirements

- iOS 15.0+ (SharePlay's minimum) — the project floor is raised to 15.0 for this reason
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved); Apple's GroupActivities is a system framework — no extra SDK
- A provisioning profile that includes the **Group Activities** capability (`com.apple.developer.group-session`)

## Setup

Open `SharePlayPlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants in `ViewController.swift` with your own. To exercise co-watching for real you need **two devices on an active FaceTime call** — a single device or the Simulator cannot meaningfully drive a group session.

## Key files

| File | Responsibility |
|---|---|
| `SharePlayPlayer/WatchTogether.swift` | Defines the `GroupActivity` and its shared `activityIdentifier`, carrying the video's source URL and key systems |
| `SharePlayPlayer/WatchTogetherWrapper.swift` | Drives the `GroupSession` lifecycle and bridges it to the Brightcove player via `AVPlayer.playbackCoordinator.coordinate(withSession:)` |
| `SharePlayPlayer/ViewController.swift` | UI (start / play-local / end), HLS source selection, session-state label |
| `SharePlayPlayer/SharePlayPlayer.entitlements` | Enables the Group Activities capability |

## How it works

`WatchTogether` is a `GroupActivity` whose `activityIdentifier` and metadata (source URL, key systems) identify the shared movie. `WatchTogetherWrapper` activates the activity, listens for incoming `GroupSession`s, and — once joined — hands the session to the Brightcove player's underlying `AVPlayer` through its `playbackCoordinator`, which keeps play/pause/seek synchronized across participants. Remote participants rebuild the shared `BCOVVideo` from the activity's source URL and load it into their own playback controller.
