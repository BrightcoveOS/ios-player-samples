# Analytics (Omniture)

The `Analytics` bucket demonstrates tracking playback with the Omniture (Adobe) analytics plugin. The Brightcove side is the `BrightcoveAMC` product of the SDK mega-package (resolved via Swift Package Manager); the Adobe side is two binaries you add manually.

The single sample, **BasicOmniturePlayer**, adds an Adobe session consumer to the playback controller and shows two configurations: Adobe Video **Media Heartbeat v2.0** (default) and Adobe **media analytics** with milestone tracking (commented out).

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved)
- An Adobe Analytics account and the two **Adobe SDK binaries added manually** — the project will not build without them

## Setup

1. Replace the sample `ADBMobileConfig.json` with the file from your own Adobe Analytics account.
2. Download the Adobe Marketing Cloud libraries, unzip them, and add the resulting `AdobeMobile.xcframework` and `MediaSDK.xcframework` to the project directory:

   ```
   https://github.com/Adobe-Marketing-Cloud/media-sdks/archive/refs/tags/ios-v2.3.0.zip
   https://github.com/Adobe-Marketing-Cloud/mobile-services/archive/refs/tags/v4.21.2-iOS.zip
   ```

3. Open `BasicOmniturePlayer.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove SDK on the first build.

The Adobe `.xcframework`s are not part of the repository — a fresh clone must download them per step 2 before the project links.

## Key files

| File | Responsibility |
|---|---|
| `BasicOmniturePlayer/ViewController.swift` | Configures the Media Heartbeat / media-analytics consumer and its delegates |
| `BasicOmniturePlayer/BasicOmniturePlayer-Bridging-Header.h` | Exposes the Adobe Objective-C headers to Swift |
| `BasicOmniturePlayer/ADBMobileConfig.json` | Adobe configuration (sample — replace with your own) |
