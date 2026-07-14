# Analytics (Omniture)

The `Analytics` bucket demonstrates tracking playback with the Omniture (Adobe) analytics plugin. The single sample, **BasicOmniturePlayer**, adds an Adobe session consumer to the playback controller and shows two configurations: Adobe Video Media Heartbeat (default) and Adobe media analytics with milestone tracking.

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** the Adobe `AdobeMobile` and `MediaSDK` frameworks, added manually. The Brightcove Omniture plugin comes via Swift Package Manager, but the project will not build without the Adobe frameworks.

## Setup

1. Replace the sample `ADBMobileConfig.json` with the file from your own Adobe Analytics account.
2. Download the Adobe [Media SDK](https://github.com/Adobe-Marketing-Cloud/media-sdks) and [Mobile Services SDK](https://github.com/Adobe-Marketing-Cloud/mobile-services) for iOS, and add the resulting `AdobeMobile.xcframework` and `MediaSDK.xcframework` to the project directory.
3. Open `BasicOmniturePlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build.

## Key files

| File | Responsibility |
|---|---|
| `BasicOmniturePlayer/ViewController.swift` | Configures the Adobe analytics consumer and its delegates |
| `BasicOmniturePlayer/BasicOmniturePlayer-Bridging-Header.h` | Exposes the Adobe headers to Swift |
| `BasicOmniturePlayer/ADBMobileConfig.json` | Adobe configuration (sample — replace with your own) |
