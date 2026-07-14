# Casting (Chromecast)

The `Cast` samples direct Brightcove playback to a Chromecast device with the Google Cast plugin (`BCOVGoogleCastManager`).

## Requirements

- **Platform:** iOS, plus a Chromecast device on the same Wi-Fi network.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** the Google Cast SDK, resolved transitively through the Brightcove Google Cast package — no manual step.

## Setup

Open the sample's `.xcodeproj` in Xcode and build; Swift Package Manager resolves the Brightcove and Google Cast packages on the first build. Replace the account constants in `ViewController.swift` with your own. Both apps declare the Bonjour / local-network discovery keys casting requires; `BasicCastPlayer` additionally needs the Wi-Fi-info entitlement and a signing team to run on device. Casting cannot be exercised in the Simulator.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicCastPlayer`](BasicCastPlayer/) | iOS | Casting to the default Google media receiver, plus a custom `GoogleCastManager` you can swap in |
| [`BrightcoveCastReceiver`](BrightcoveCastReceiver/) | iOS | Casting to Brightcove's CAF receiver, which adds DRM, SSAI, and HLSv3-or-superior support |
