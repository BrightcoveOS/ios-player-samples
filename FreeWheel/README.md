# FreeWheel

The `FreeWheel` bucket demonstrates ads managed by FreeWheel (linear and companion). The Brightcove side is the `BrightcoveFW` product (resolved via Swift Package Manager); the FreeWheel AdManager SDK is **not** distributed via Swift Package Manager and must be added manually.

The single sample, **BasicFreeWheelPlayer**, bridges Brightcove to FreeWheel with a `BCOVFWSessionProvider` and builds a per-session ad request with pre-roll, two mid-rolls, and a post-roll.

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved)
- The **FreeWheel AdManager SDK added manually** — the "AdManager Dynamic Build", downloaded from the [FreeWheel website](https://hub.freewheel.tv/display/techdocs/AdManager+SDK+Integration+Downloads)

## Setup

1. Open `BasicFreeWheelPlayer.xcodeproj` in Xcode; Swift Package Manager resolves the Brightcove SDK on the first build.
2. Download the FreeWheel **"AdManager Dynamic Build"** and drag `AdManager.xcframework` onto the project in the Project Navigator. When prompted, add it to the **BasicFreeWheelPlayer** target.
3. Under the target's **Frameworks, Libraries and Embedded Content**, set `AdManager.xcframework` to **Embed & Sign**.

`AdManager.xcframework` is not part of the repository, so a fresh clone will not link until you add it. If you keep the framework outside the project folder, also add its parent directory to the target's **Framework Search Paths**.

The FreeWheel demo endpoint constants (`kNetworkId`, `kServerURL`, `kPlayerProfile`, `kSiteSectionId`, `kVideoAssetId`) are at the top of `ViewController.swift`; the sample enables arbitrary loads (`NSAllowsArbitraryLoads`) because the demo ad server is HTTP.
