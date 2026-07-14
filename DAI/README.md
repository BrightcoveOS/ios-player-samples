# DAI (Google Dynamic Ad Insertion)

The Brightcove DAI plugin integrates the player with Google's Interactive Media Ads for a server-side stream request — a single stitched stream carrying both ads and content, for VOD or live.

## Requirements

- **Platform:** iOS and tvOS.
- **Minimum OS:** iOS 14.0, tvOS 15.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** Google IMA, resolved transitively through the Brightcove DAI package — you do not add the Google package yourself.

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK and Google IMA on the first build. The Google DAI demo stream identifiers are constants in the source. The samples request App Tracking Transparency authorization and enable arbitrary loads so ad creatives can be fetched — a sample-only convenience.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicDAIPlayer-iOS`](BasicDAIPlayer-iOS/) | iOS | Two stream-request policies via a menu: Video Properties (source-id + video-id, VOD) and Asset Key (live) |
| [`BasicDAIPlayer-tvOS`](BasicDAIPlayer-tvOS/) | tvOS | The Video Properties policy on tvOS with `BCOVTVPlayerView` |
