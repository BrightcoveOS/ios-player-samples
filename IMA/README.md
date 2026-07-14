# IMA (Google Interactive Media Ads)

The Brightcove IMA plugin integrates the player with Google's Interactive Media Ads to request and track VAST and VMAP ads.

Adding the `BrightcoveIMA` product through Swift Package Manager automatically resolves the matching Google Ads IMA SDK for iOS and tvOS — you don't add the Google package yourself.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicIMAPlayer-iOS`](BasicIMAPlayer-iOS/) | iOS | Three ad configurations via a menu — VMAP (ad rules), VAST cue points, and VAST + Open Measurement (OMID) — with `BCOVPUIPlayerView` and companion ad slots |
| [`NativeControlsIMAPlayer-tvOS`](NativeControlsIMAPlayer-tvOS/) | tvOS | A VMAP configuration rendered through Apple's native `AVPlayerViewController` controls |

For IMA in a SwiftUI app, see [`SwiftUI/SwiftUIPlayerIMA`](../SwiftUI/SwiftUIPlayerIMA/).

## Requirements

- iOS 14.0+ / tvOS 15.0+
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved); Google IMA arrives transitively — no manual step

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK and Google IMA on the first build. The Google sample ad-tag URLs are constants in the source (`BCOVVideo+Helpers.swift` on iOS; the top of `ViewController.swift` on tvOS). The samples request App Tracking Transparency authorization and enable arbitrary loads (`NSAllowsArbitraryLoads`) so ad creatives can be fetched; this is a sample-only convenience.
