# Declarative UI (SwiftUI)

The `SwiftUI` bucket demonstrates hosting the Brightcove player in a SwiftUI app. The SDK's player surfaces are UIKit, so each sample bridges them into SwiftUI with `UIViewRepresentable` / `UIViewControllerRepresentable` and drives the UI from `BCOVPlaybackController` delegate callbacks.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`SwiftUIPlayer`](SwiftUIPlayer/) | iOS 16+ | Three side-by-side bridge approaches (`AVPlayerViewController`, `BCOVPUIPlayerView`, `BCOVPUIPlayerViewController`) and playlist playback |
| [`CustomControls`](CustomControls/) | iOS 14+ | SwiftUI custom controls driven by an `ObservableObject`, with WebVTT thumbnail scrubbing |
| [`SwiftUIPlayerIMA`](SwiftUIPlayerIMA/) | iOS 17+ | Google IMA ads (VMAP, VAST, VAST+OMID) in a SwiftUI player |

For UIKit custom controls, see [`PlayerUI/CustomControls`](../PlayerUI/CustomControls/).

## Requirements

- iOS 14.0+, rising per sample (`SwiftUIPlayer` iOS 16, `SwiftUIPlayerIMA` iOS 17) — see each sample's README
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved); `SwiftUIPlayerIMA` additionally pulls Google IMA transitively — no manual step

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK (and, for `SwiftUIPlayerIMA`, Google IMA) on the first build. Replace the account constants (`Config.swift` in `SwiftUIPlayerIMA`, the model files in the others) with your own. FairPlay-protected content does not play in the Simulator (each sample shows a warning alert).
