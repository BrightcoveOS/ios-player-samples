# Playback

The `Player` samples demonstrate the core Brightcove SDK: retrieving video from Video Cloud and playing it with the built-in `BCOVPUIPlayerView` (iOS) or `BCOVTVPlayerView` (tvOS) controls, plus the common playback scenarios an app needs beyond a single video.

## Requirements

- **Platform:** iOS and tvOS.
- **Minimum OS:** iOS 14.0, tvOS 15.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** none — the Brightcove SDK is resolved by Swift Package Manager on the first build.

## Setup

Open the sample's `.xcodeproj` in Xcode and build. Each sample declares its own account constants (`kAccountId`, `kPolicyKey`, and a content id) at the top of its main source file; replace them with your own to play your content. FairPlay-protected content plays only on a device, and `DVRLive` needs a live HLS URL you supply.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`VideoCloudBasicPlayer`](VideoCloudBasicPlayer/) | iOS | The reference basic player — also AirPlay, background audio, Picture-in-Picture, lock-screen / Now Playing, and audio-only assets |
| [`AppleTV-tvOS`](AppleTV-tvOS/) | tvOS | The tvOS player with `BCOVTVPlayerView` and a custom info panel |
| [`TableViewPlayer`](TableViewPlayer/) | iOS | Many independent players in a `UITableView`, with buffer tuning and scroll-driven play/pause |
| [`DVRLive`](DVRLive/) | iOS | The live / DVR control layout, driving playback from a raw HLS URL |
| [`Video360`](Video360/) | iOS | 360°/VR video and the VR-goggles projection mode |
| [`VerticalPlayer`](VerticalPlayer/) | iOS | A full-bleed vertical (TikTok-style) paging feed |
| [`VideoPreloading`](VideoPreloading/) | iOS | Double-buffered preloading of the next video for seamless advance |
| [`NativeControls`](NativeControls/) | iOS | Apple's native `AVPlayerViewController` controls instead of the Brightcove UI |
