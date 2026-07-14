# Offline Playback

The `Offline` bucket demonstrates downloading HLS videos — including FairPlay-protected ones — and playing them back with or without a network connection. The single sample, **OfflinePlayer**, is a three-tab UIKit app: a video list to download from, a downloads queue with progress, and a settings tab for FairPlay license type (rental vs. purchase) and preferred bitrate.

## Requirements

- **Platform:** iOS (device only — iOS allows neither downloads nor FairPlay playback in the Simulator).
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none — offline download and playback are built into the core SDK. Requires a Brightcove account with Dynamic Delivery.

## Setup

Open `OfflinePlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants with your own, then run on a device to download and play back offline. For a deeper walkthrough, see the SDK's [Offline Playback guide](https://github.com/brightcove/brightcove-player-sdk-ios/blob/master/OfflinePlayback.md).

## Key files

| File | Responsibility |
|---|---|
| `OfflinePlayer/DownloadManager.swift` | Download / preload queues, FairPlay license parameters, download-progress callbacks |
| `OfflinePlayer/VideoManager.swift` | Playlist retrieval, download-size estimation, thumbnail caching |
| `OfflinePlayer/VideosViewController.swift`, `DownloadsViewController.swift`, `SettingsViewController.swift` | The list / downloads / settings tabs |
