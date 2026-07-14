# Declarative UI (SwiftUI)

The `SwiftUI` samples demonstrate hosting the Brightcove player in a SwiftUI app. The SDK's player surfaces are UIKit, so each sample bridges them into SwiftUI with `UIViewRepresentable` / `UIViewControllerRepresentable` and drives the UI from `BCOVPlaybackController` delegate callbacks.

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0, rising per sample (`SwiftUIPlayer` iOS 16, `SwiftUIPlayerIMA` iOS 17).
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none for most; `SwiftUIPlayerIMA` pulls Google IMA transitively via the Brightcove IMA package, with no manual step.

## Setup

Open the sample's `.xcodeproj` in Xcode and build. Replace the account constants (`Config.swift` in `SwiftUIPlayerIMA`, the model files in the others) with your own. FairPlay-protected content plays only on a device. For UIKit custom controls, see [`PlayerUI/CustomControls`](../PlayerUI/CustomControls/).

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`SwiftUIPlayer`](SwiftUIPlayer/) | iOS 16+ | Three side-by-side bridge approaches (`AVPlayerViewController`, `BCOVPUIPlayerView`, `BCOVPUIPlayerViewController`) and playlist playback |
| [`CustomControls`](CustomControls/) | iOS 14+ | SwiftUI custom controls driven by an `ObservableObject`, with WebVTT thumbnail scrubbing |
| [`SwiftUIPlayerIMA`](SwiftUIPlayerIMA/) | iOS 17+ | Google IMA ads (VMAP, VAST, VAST+OMID) in a SwiftUI player |
