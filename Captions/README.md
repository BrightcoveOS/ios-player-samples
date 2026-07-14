# Captions

The `Captions` bucket demonstrates two complementary approaches to subtitles and closed captions. Both rely only on the core `BrightcovePlayerSDK` framework — there is no extra package.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicSidecarSubtitlesPlayer`](BasicSidecarSubtitlesPlayer/) | iOS | **Adding** an external WebVTT subtitle track to an HLS manifest at runtime, then letting the SDK render it normally |
| [`SubtitleRendering`](SubtitleRendering/) | iOS | **Bypassing** the built-in caption engine to parse WebVTT yourself and render cues in a custom view, for full control over positioning and appearance |

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved) — no extra SDK

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants in `ViewController.swift` with your own. Each sample uses a demo video chosen to carry the relevant text tracks. FairPlay-protected content does not play in the Simulator (each sample shows a warning alert).
