# Brightcove Player SDK for iOS Samples

Sample applications for the [Brightcove Native Player SDKs](https://sdks.support.brightcove.com/getting-started/brightcove-native-player-sdks.html) for iOS and tvOS, organized by capability.

Most samples consume the SDK through [Swift Package Manager](https://www.swift.org/documentation/package-manager/); the `Flutter` and `ReactNative` samples use [CocoaPods][cocoapods]. Each top-level folder is one capability area (or a host framework) and carries its own README; this page is the index.

## Prerequisites

1. Xcode 15.0+
1. iOS 14.0+ or tvOS 15.0+ — some samples require a higher target (see the [coverage matrix](#capability-coverage) or the sample's README)
1. [CocoaPods][cocoapods] 1.11+ — only for the `Flutter` and `ReactNative` samples

An Apple Developer Program account is required to run a sample on a physical device. Edit the sample's bundle identifier to make it unique to your organization before provisioning.

## Getting started

Open the sample's `.xcodeproj` in Xcode and build. Swift Package Manager resolves the Brightcove SDK — and, where applicable, the Google IMA and Google Cast packages — automatically on the first build. There is no separate install step. First-build resolution needs network access; Xcode then caches the packages for offline use.

A few samples require an additional third-party SDK that is not distributed through Swift Package Manager (FreeWheel, INVIDI Pulse, or Adobe) and must be added manually; those samples document the extra steps in their own README.

### CocoaPods (Flutter and ReactNative samples only)

> **Note:** Brightcove's CocoaPods distribution is deprecated as of SDK 7.2.15 and stops receiving updates once the CocoaPods Trunk becomes read-only (expected late 2026). New integrations should use Swift Package Manager; these two samples remain on CocoaPods until their framework integrations migrate.

Run `pod repo update` to pull the latest Brightcove podspecs, then follow the sample's README (`pod install`, open the generated `.xcworkspace`). For SDK development you can switch between the published SDK and a local build with the `BRIGHTCOVE_LOCAL_SDK` environment variable, configured in `Podfile.common.rb` at the repository root:

```bash
pod install                              # published SDK (default)
BRIGHTCOVE_LOCAL_SDK=true pod install    # local SDK at ../videocloud_agave
BRIGHTCOVE_LOCAL_SDK=/path/to/sdk pod install   # local SDK at a custom path
```

## Capability coverage

Each capability maps to one bucket folder. A capability available on both platforms ships an `-iOS` and a `-tvOS` variant; an iOS-only capability sits directly in its bucket.

| Capability | iOS / tvOS sample(s) |
|---|---|
| Basic playback | [`Player/VideoCloudBasicPlayer`](Player/VideoCloudBasicPlayer/) (iOS), [`Player/AppleTV-tvOS`](Player/AppleTV-tvOS/) (tvOS) |
| Video list / playlist | [`Player/TableViewPlayer`](Player/TableViewPlayer/) |
| Live / DVR | [`Player/DVRLive`](Player/DVRLive/) |
| 360° video | [`Player/Video360`](Player/Video360/) |
| Audio-only playback | Demonstrated within [`Player/VideoCloudBasicPlayer`](Player/VideoCloudBasicPlayer/) |
| Picture-in-Picture | Demonstrated within [`Player/VideoCloudBasicPlayer`](Player/VideoCloudBasicPlayer/) and [`SwiftUI/SwiftUIPlayer`](SwiftUI/SwiftUIPlayer/) |
| Thumbnail scrubbing | Demonstrated within [`SwiftUI/CustomControls`](SwiftUI/CustomControls/) |
| Custom controls | [`PlayerUI/CustomControls`](PlayerUI/CustomControls/) (UIKit), [`SwiftUI/CustomControls`](SwiftUI/CustomControls/) (SwiftUI) |
| Declarative UI | [`SwiftUI/`](SwiftUI/) (three apps) |
| Captions | [`Captions/`](Captions/) (two apps) |
| DRM (FairPlay) | [`DRM/BasicFairPlayPlayer`](DRM/) |
| Offline playback | [`Offline/OfflinePlayer`](Offline/) |
| IMA ads | [`IMA/`](IMA/) (iOS + tvOS), [`SwiftUI/SwiftUIPlayerIMA`](SwiftUI/SwiftUIPlayerIMA/) |
| DAI | [`DAI/`](DAI/) (iOS + tvOS) |
| SSAI | [`SSAI/`](SSAI/) (iOS + tvOS, plus Server-Side Live + IMA) |
| FreeWheel | [`FreeWheel/BasicFreeWheelPlayer`](FreeWheel/) |
| Pulse | [`Pulse/`](Pulse/) (iOS + tvOS) |
| Analytics (Omniture / Adobe) | [`Analytics/BasicOmniturePlayer`](Analytics/) |
| Casting (Chromecast) | [`Cast/`](Cast/) (two apps) |
| Vertical video | [`Player/VerticalPlayer`](Player/VerticalPlayer/) |
| Video preloading | [`Player/VideoPreloading`](Player/VideoPreloading/) |
| Co-watching (SharePlay) | [`SharePlay/SharePlayPlayer`](SharePlay/) |

The `Player` and `PlayerUI` buckets also carry UI samples that refine the above rather than add a new capability: Apple's native `AVPlayerViewController` controls ([`Player/NativeControls`](Player/NativeControls/)), runtime control-layout customization ([`PlayerUI/PlayerUICustomization`](PlayerUI/PlayerUICustomization/)), and view-strategy composition ([`PlayerUI/ViewStrategy`](PlayerUI/ViewStrategy/)).

## Samples by area

- **Playback** — [`Player/`](Player/): basic Video Cloud playback, playlists in a table view, live/DVR, 360°/VR, vertical video, preloading, native controls, and a tvOS player.
- **UI Customization** — [`PlayerUI/`](PlayerUI/): fully custom controls, control-layout customization with VoiceOver/accessibility, and the view strategy.
- **Advertising** — [`IMA/`](IMA/) (Google Interactive Media Ads), [`DAI/`](DAI/) (Google Dynamic Ad Insertion), [`SSAI/`](SSAI/) (Brightcove Server-Side Ad Insertion), [`FreeWheel/`](FreeWheel/), and [`Pulse/`](Pulse/) (INVIDI).
- **DRM & Offline** — [`DRM/`](DRM/) (FairPlay) and [`Offline/`](Offline/) (downloading and playing HLS, including FairPlay-protected, with or without a network connection).
- **Casting** — [`Cast/`](Cast/): sending video to a Chromecast with the Google Cast plugin, using the default receiver or Brightcove's CAF receiver.
- **Captions** — [`Captions/`](Captions/): sidecar WebVTT subtitles and custom subtitle rendering.
- **Analytics** — [`Analytics/`](Analytics/): tracking with the Omniture (Adobe) plugin.
- **Declarative UI** — [`SwiftUI/`](SwiftUI/): hosting the Brightcove player in SwiftUI, with and without ads.
- **Host Frameworks** — [`Flutter/`](Flutter/) and [`ReactNative/`](ReactNative/): embedding the native player in cross-platform apps (CocoaPods).
- **Co-watching** — [`SharePlay/`](SharePlay/): synchronizing playback across a FaceTime call with Apple's GroupActivities. iOS only.

## About Swift

The Swift sample apps are written in Swift 5.

## Localization

The Brightcove iOS SDK is localized for English (en), Arabic (ar), German (de), Spanish (es), French (fr), Japanese (ja), Korean (ko), Chinese traditional (zh-hant), and Chinese simplified (zh-hans). These sample projects take advantage of that localization:

- `Player/VideoCloudBasicPlayer`
- `Player/AppleTV-tvOS`
- `IMA/BasicIMAPlayer-iOS`
- `SSAI/BasicSSAIPlayer-iOS`

## Support

Use the [Support Portal](https://supportportal.brightcove.com/s/login/) or contact your Account Manager. To hear about new SDK releases, subscribe to the Brightcove Native Player SDKs [Google Group](https://groups.google.com/g/brightcove-native-player-sdks).

[cocoapods]: http://www.cocoapods.org
