# UI Customization

The `PlayerUI` bucket demonstrates customizing the player's look and feel with UIKit — from restyling the built-in controls to replacing them entirely, and controlling how the SDK's video view is composed into your own view hierarchy.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`CustomControls`](CustomControls/) | iOS | Fully hand-built UIKit controls (no `BCOVPUIPlayerView`) and a custom Audio & Subtitles menu |
| [`PlayerUICustomization`](PlayerUICustomization/) | iOS | Switching among six control layouts at runtime, plus the VoiceOver/accessibility API |
| [`ViewStrategy`](ViewStrategy/) | iOS | Composing the SDK video view and custom controls with a `BCOVPlaybackControllerViewStrategy` closure |

For custom controls in a SwiftUI app, see [`SwiftUI/CustomControls`](../SwiftUI/CustomControls/).

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved) — no extra SDK

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build. Replace the account constants at the top of `ViewController.swift` with your own. FairPlay-protected content does not play in the Simulator (each sample shows a warning alert).
