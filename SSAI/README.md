# SSAI (Server-Side Ad Insertion)

The `SSAI` samples demonstrate Brightcove Server-Side Ad Insertion — ads stitched into the stream server-side and delivered through Dynamic Delivery. Playback chains a Brightcove SSAI session provider on top of the FairPlay provider, and content is fetched with an ad-config id.

## Requirements

- **Platform:** iOS and tvOS.
- **Minimum OS:** iOS 14.0, tvOS 15.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** the Brightcove SSAI package (iOS also links the Open Measurement package); the SLS-IMA samples additionally use the Brightcove IMA package, which brings Google IMA transitively. No manual step.

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the packages on the first build.

- The **Basic SSAI** samples ship with a runnable demo account and ad-config id, so they play out of the box.
- The **SLS-IMA** samples ship with placeholder constants and do not run until you supply your own account id, policy key, video id, ad-config id, and VMAP ad-tag URL.

The samples request App Tracking Transparency authorization and enable arbitrary loads so ad creatives can be fetched — a sample-only convenience.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicSSAIPlayer-iOS`](BasicSSAIPlayer-iOS/) | iOS | Dynamic Delivery SSAI VOD playback with companion ad slots; optional Open Measurement |
| [`BasicSSAIPlayer-tvOS`](BasicSSAIPlayer-tvOS/) | tvOS | The same SSAI playback on tvOS with `BCOVTVPlayerView` |
| [`SLS-IMA-iOS`](SLS-IMA-iOS/) | iOS | Client-side Google IMA ads (a VMAP tag) layered on SSAI, for a Server-Side Live + IMA workflow |
| [`SLS-IMA-tvOS`](SLS-IMA-tvOS/) | tvOS | The same IMA-over-SSAI chain on tvOS |
