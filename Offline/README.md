# Offline Playback

The `Offline` bucket demonstrates downloading HLS videos — including FairPlay-protected ones — and playing them back with or without a network connection, using `BCOVOfflineVideoManager` from the core SDK. There is no extra package.

The single sample, **OfflinePlayer**, is a three-tab UIKit app: a video list to download from, a downloads queue with progress, and a settings tab for FairPlay license type (rental vs. purchase) and preferred bitrate.

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved) — no extra SDK
- A Brightcove account with **Dynamic Delivery**
- A **physical device** — iOS allows neither video downloads nor FairPlay playback in the Simulator

## Setup

Open `OfflinePlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants with your own, then run on a device to download and play back offline.

## Key files

| File | Responsibility |
|---|---|
| `OfflinePlayer/DownloadManager.swift` | Download / preload queues, FairPlay license parameters, `BCOVOfflineVideoManagerDelegate` progress callbacks |
| `OfflinePlayer/VideoManager.swift` | Playlist retrieval, download-size estimation, thumbnail caching |
| `OfflinePlayer/VideosViewController.swift`, `DownloadsViewController.swift`, `SettingsViewController.swift` | The list / downloads / settings tabs |

## Reference

See ["iOS App Developer's Guide to Video Downloading and Offline Playback with HLS in the Brightcove Player SDK for iOS"](https://github.com/brightcove/brightcove-player-sdk-ios/blob/master/OfflinePlayback.md) for details.
