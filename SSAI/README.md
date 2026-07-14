# SSAI (Server-Side Ad Insertion)

The `SSAI` bucket demonstrates Brightcove Server-Side Ad Insertion — ads stitched into the stream server-side and delivered through Dynamic Delivery. Playback is built by chaining a `BrightcoveSSAI` session provider on top of the FairPlay provider (`createSSAISessionProvider`), and content is fetched with an ad-config id.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicSSAIPlayer-iOS`](BasicSSAIPlayer-iOS/) | iOS | Dynamic Delivery SSAI VOD playback with companion ad slots; opt-in IAB Open Measurement and Google PAL |
| `BasicSSAIPlayer-tvOS` | tvOS | The same SSAI playback on tvOS with `BCOVTVPlayerView` (no companion slots) |
| `SLS-IMA-iOS` | iOS | Layering **client-side Google IMA** ads (a VMAP tag) on top of SSAI — the FairPlay → IMA → SSAI provider chain, for a Server-Side Live + IMA workflow |
| `SLS-IMA-tvOS` | tvOS | The same IMA-over-SSAI chain on tvOS |

## Requirements

- iOS 14.0+ / tvOS 15.0+
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved); the SSAI samples link the `BrightcoveSSAI` product (iOS also links `OMSDK_Brightcove` for Open Measurement), and the SLS-IMA samples additionally link `BrightcoveIMA`, which brings Google IMA transitively — no manual step

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the packages on the first build.

- The **Basic SSAI** samples ship with a runnable demo account and ad-config id, so they play out of the box.
- The **SLS-IMA** samples ship with placeholder constants (`insertyour…here`) and do **not** run until you supply your own account id, policy key, video id, ad-config id, and VMAP ad-tag URL in `ViewController.swift`.

The samples request App Tracking Transparency authorization and enable arbitrary loads (`NSAllowsArbitraryLoads`) so ad creatives can be fetched; this is a sample-only convenience. `BasicSSAIPlayer-iOS` has its own README covering the Open Measurement and PAL integrations in detail.
