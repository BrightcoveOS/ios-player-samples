# Captions

The `Captions` samples demonstrate two complementary approaches to subtitles and closed captions, both using only the core SDK.

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none — SidecarSubtitles is part of the core SDK.

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants in `ViewController.swift` with your own. Each sample uses a demo video chosen to carry the relevant text tracks. FairPlay-protected content plays only on a device.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicSidecarSubtitlesPlayer`](BasicSidecarSubtitlesPlayer/) | iOS | Adding an external WebVTT subtitle track to an HLS manifest at runtime |
| [`SubtitleRendering`](SubtitleRendering/) | iOS | Parsing WebVTT yourself and rendering cues in a custom view for full control over positioning and appearance |
