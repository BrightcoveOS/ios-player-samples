# DAI (Dynamic Ad Insertion)

The Brightcove DAI plugin integrates the player with Google's Interactive Media Ads for a server-side **stream request** — a single stitched stream carrying both ads and content, for VOD or live.

Adding the `BrightcoveDAI` product through Swift Package Manager automatically resolves the matching Google Ads IMA SDK for iOS and tvOS — you don't add the Google package yourself.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| `BasicDAIPlayer-iOS` | iOS | Two stream-request policies via a menu: Video Properties (source-id + video-id, VOD) and Asset Key (live) |
| `BasicDAIPlayer-tvOS` | tvOS | The Video Properties policy on tvOS with `BCOVTVPlayerView` |

## Requirements

- iOS 14.0+ / tvOS 15.0+
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved); Google IMA arrives transitively — no manual step

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK and Google IMA on the first build. The Google DAI demo stream identifiers are constants at the top of `BaseViewController.swift` (iOS) / `ViewController.swift` (tvOS). The samples request App Tracking Transparency authorization and enable arbitrary loads (`NSAllowsArbitraryLoads`) so ad creatives can be fetched; this is a sample-only convenience.
