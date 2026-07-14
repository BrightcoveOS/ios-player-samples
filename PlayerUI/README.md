# UI Customization

The `PlayerUI` samples demonstrate customizing the player's look and feel with UIKit — from restyling the built-in controls to replacing them entirely, and controlling how the SDK's video view is composed into your own view hierarchy.

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none — the Brightcove SDK is resolved by Swift Package Manager on the first build.

## Setup

Open the sample's `.xcodeproj` in Xcode and build. Replace the account constants at the top of `ViewController.swift` with your own. FairPlay-protected content plays only on a device. For custom controls in a SwiftUI app, see [`SwiftUI/CustomControls`](../SwiftUI/CustomControls/).

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`CustomControls`](CustomControls/) | iOS | Fully hand-built UIKit controls (no `BCOVPUIPlayerView`) and a custom Audio & Subtitles menu |
| [`PlayerUICustomization`](PlayerUICustomization/) | iOS | Switching among six control layouts at runtime, plus the VoiceOver/accessibility API |
| [`ViewStrategy`](ViewStrategy/) | iOS | Composing the SDK video view and custom controls with a `BCOVPlaybackControllerViewStrategy` closure |
