# IMA (Google Interactive Media Ads)

The Brightcove IMA plugin integrates the player with Google's Interactive Media Ads to request and track VAST and VMAP ads.

## Requirements

- **Platform:** iOS and tvOS.
- **Minimum OS:** iOS 14.0, tvOS 15.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** Google IMA, resolved transitively through the Brightcove IMA package — you do not add the Google package yourself.

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK and Google IMA on the first build. The sample ad-tag URLs are constants in the source. The samples request App Tracking Transparency authorization and enable arbitrary loads so ad creatives can be fetched — a sample-only convenience. For IMA in a SwiftUI app, see [`SwiftUI/SwiftUIPlayerIMA`](../SwiftUI/SwiftUIPlayerIMA/).

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicIMAPlayer-iOS`](BasicIMAPlayer-iOS/) | iOS | Three ad configurations via a menu — VMAP (ad rules), VAST cue points, and VAST + Open Measurement (OMID) — with `BCOVPUIPlayerView` and companion ad slots |
| [`NativeControlsIMAPlayer-tvOS`](NativeControlsIMAPlayer-tvOS/) | tvOS | A VMAP configuration rendered through Apple's native `AVPlayerViewController` controls |
