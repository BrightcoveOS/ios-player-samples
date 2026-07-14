# Co-watching (SharePlay)

The `SharePlay` bucket demonstrates synchronizing Brightcove playback across the participants of a FaceTime call using Apple's GroupActivities framework; it is iOS only. The single sample, **SharePlayPlayer**, lets the user start a shared session, play locally, or end the session, keeping playback position in sync for everyone by handing the session to the player's `AVPlayer` playback coordinator.

## Requirements

- **Platform:** iOS (two devices on a FaceTime call are needed to exercise co-watching).
- **Minimum OS:** iOS 15.0 (SharePlay's minimum).
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none — Apple's GroupActivities is a system framework. Requires a provisioning profile with the Group Activities capability.

## Setup

Open `SharePlayPlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants in `ViewController.swift` with your own. A single device or the Simulator cannot meaningfully drive a group session.

## Key files

| File | Responsibility |
|---|---|
| `SharePlayPlayer/WatchTogether.swift` | Defines the `GroupActivity` and its shared identifier |
| `SharePlayPlayer/WatchTogetherWrapper.swift` | Drives the group-session lifecycle and bridges it to the player's `AVPlayer` playback coordinator |
| `SharePlayPlayer/ViewController.swift` | UI (start / play-local / end), HLS source selection, session-state label |
