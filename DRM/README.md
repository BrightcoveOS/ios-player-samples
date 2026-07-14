# DRM (FairPlay)

The `DRM` bucket demonstrates playback of FairPlay-protected video. The single sample, **BasicFairPlayPlayer**, plays one FairPlay-encrypted video from Video Cloud with the standard `BCOVPUIPlayerView` controls.

## Requirements

- **Platform:** iOS (device only — FairPlay-protected video does not play in the Simulator).
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none — FairPlay is built into the core SDK.

## Setup

Open `BasicFairPlayPlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace `kAccountId`, `kPolicyKey`, and `kVideoId` at the top of `ViewController.swift` with your own, then run on a device. The sample uses Brightcove-hosted FairPlay, so the account supplies the FairPlay credentials; those credentials are acquired from Apple (Brightcove does not provide them).

## Key files

| File | Responsibility |
|---|---|
| `BasicFairPlayPlayer/ViewController.swift` | Builds the FairPlay session provider, fetches the video, drives `BCOVPUIPlayerView` |
| `BasicFairPlayPlayer/AppDelegate.swift` | Configures `AVAudioSession` for playback |
