# Casting (Chromecast)

The `Cast` bucket demonstrates directing Brightcove playback to a Chromecast device with the Google Cast plugin (`BCOVGoogleCastManager`). The Google Cast SDK is pulled in transitively through the `BrightcoveGoogleCast` Swift Package product — there is no manual framework step.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicCastPlayer`](BasicCastPlayer/) | iOS | Casting to the **default** Google media receiver, plus a fully custom `GoogleCastManager` you can swap in |
| [`BrightcoveCastReceiver`](BrightcoveCastReceiver/) | iOS | Casting to **Brightcove's CAF receiver** (`BCOVReceiverAppConfig`), which adds DRM, SSAI, and HLSv3-or-superior support |

The default receiver used by `BasicCastPlayer` supports HLSv3 / DASH / MP4 and neither DRM nor ads; `BrightcoveCastReceiver` uses Brightcove's receiver application to lift those limits.

## Requirements

- iOS 14.0+ (iPhone / iPad)
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved); the `BrightcoveGoogleCast` product brings the Google Cast SDK transitively
- A **physical Chromecast device** on the same Wi-Fi network — casting cannot be exercised in the Simulator

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove and Google Cast packages on the first build. Replace the account constants in `ViewController.swift` with your own. Both apps declare the Bonjour / local-network discovery keys casting requires in `Info.plist`; `BasicCastPlayer` additionally needs the Wi-Fi-info entitlement and a signing team to run on device.
