# DRM (FairPlay)

The `DRM` bucket demonstrates playback of FairPlay-protected video. FairPlay support is built into the core `BrightcovePlayerSDK` framework — there is no separate DRM package to add.

The single sample, **BasicFairPlayPlayer**, plays one FairPlay-encrypted video from Video Cloud using the standard `BCOVPUIPlayerView` controls.

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved) — no extra SDK
- A **physical device** — FairPlay-protected video does not play in the Simulator

## Setup

Open `BasicFairPlayPlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace `kAccountId`, `kPolicyKey`, and `kVideoId` at the top of `ViewController.swift` with your own account, then run on a device.

## Key files

| File | Responsibility |
|---|---|
| `BasicFairPlayPlayer/ViewController.swift` | Builds the FairPlay session provider, fetches the video, drives `BCOVPUIPlayerView` |
| `BasicFairPlayPlayer/AppDelegate.swift` | Configures `AVAudioSession` for playback |
| `BasicFairPlayPlayer/Base.lproj/Main.storyboard` | Hosts the video container view |

## A note about FairPlay credentials

The sample creates a Brightcove-hosted FairPlay session:

```swift
let authProxy = BCOVFPSBrightcoveAuthProxy(withPublisherId: nil, applicationId: nil)
let fps = sdkManager.createFairPlaySessionProvider(withApplicationCertificate: nil,
                                                    authorizationProxy: authProxy,
                                                    upstreamSessionProvider: nil)
```

Passing `nil` lets the account's FairPlay configuration supply the publisher id, application id, and application certificate. FairPlay credentials themselves are acquired from Apple — Brightcove does not provide them — and are configured on the Video Cloud account. Because the Simulator cannot decrypt FairPlay content, the sample shows a warning alert and stops when it detects `video.usesFairPlay` under `#if targetEnvironment(simulator)`; develop on an actual device.
