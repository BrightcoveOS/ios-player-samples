Brightcove Player SDK for iOS Samples
=====================================

Learn more about the [Brightcove Native Player SDKs](https://sdks.support.brightcove.com/getting-started/brightcove-native-player-sdks.html).

ios-player-samples.git is a collection of sample applications for the Brightcove Player SDKs for iOS and tvOS, organized by capability. The sample apps consume the Brightcove SDK through [Swift Package Manager](https://www.swift.org/documentation/package-manager/). The `Flutter` and `ReactNative` samples instead use [CocoaPods][cocoapods].

### Prerequisites

1. Xcode 15.0+ (the `SwiftUI/SwiftUIPlayerIMA` sample requires Xcode 16.0+)
1. iOS 14.0+ or tvOS 15.0+ (some samples require a higher deployment target — see the sample's own README)
1. [CocoaPods][cocoapods] 1.11+ — only for the `Flutter` and `ReactNative` samples

An Apple Developer Program account is required to run any sample app on a physical device. In order to provision your device, edit the sample app bundle identifier to make it unique to your organization.

### Swift Package Manager

Most samples consume the Brightcove SDK through Swift Package Manager. Open the sample's `.xcodeproj` in Xcode and the required packages are resolved automatically on the first build — there is no separate install step.

### CocoaPods (Flutter and ReactNative samples only)

> **Note:** Brightcove's CocoaPods distribution is deprecated as of SDK 7.2.15 and will stop receiving updates once the CocoaPods Trunk becomes read-only (expected late 2026). New integrations should use Swift Package Manager; these two samples remain on CocoaPods until their framework integrations migrate.

The `Flutter` and `ReactNative` samples use CocoaPods. To ensure you are using the latest releases of the Brightcove software components, update your Podspec repository before building them:

```
pod repo update
```

For SDK development against those two samples, you can switch between the published SDK and a local development build with the `BRIGHTCOVE_LOCAL_SDK` environment variable (configured in `Podfile.common.rb` at the repository root):

```bash
# Published SDK (default)
pod install

# Local SDK at the default path (../videocloud_agave)
BRIGHTCOVE_LOCAL_SDK=true pod install

# Local SDK at a custom path
BRIGHTCOVE_LOCAL_SDK=/path/to/your/sdk pod install
```

### About Swift

The Swift sample apps are written in Swift 5.

### Instructions

Unless otherwise instructed, samples can be run by following these steps:

1. Open the sample's `.xcodeproj` in Xcode.
1. Build and run. Swift Package Manager resolves the Brightcove SDK — and, where applicable, the Google IMA and Google Cast packages — automatically on the first build.
1. Several samples require an additional third-party SDK (for example FreeWheel, Pulse, or Adobe) that must be added manually; those samples have their own README.md with the extra steps.

The `Flutter` and `ReactNative` samples use CocoaPods instead — run `pod install` and open the generated `.xcworkspace`, as described in their READMEs.

Note: package resolution requires network access on the first build. Once resolved, Xcode caches the packages for offline use.

### Samples

Samples are grouped by capability. Each top-level folder is one capability area (or a host framework); the groups below map those folders to what they demonstrate. A capability available on both platforms has an `-iOS` and a `-tvOS` variant; an iOS-only capability sits directly in its folder.

#### Playback (`Player`)

The `Player` samples demonstrate the core SDK: basic Video Cloud playback (`VideoCloudBasicPlayer`), native `AVPlayerViewController` controls (`NativeControls`), playlists in a table view (`TableViewPlayer`), video preloading (`VideoPreloading`), DVR/live (`DVRLive`), vertical video (`VerticalPlayer`), 360°/VR (`Video360`), and a tvOS player (`AppleTV-tvOS`).

#### UI Customization (`PlayerUI`)

The `PlayerUI` samples demonstrate customizing the player's look and feel: fully custom controls (`CustomControls`), control-layout customization and VoiceOver/accessibility (`PlayerUICustomization`), and the view strategy (`ViewStrategy`).

#### Advertising (`IMA`, `DAI`, `SSAI`, `FreeWheel`, `Pulse`)

- **IMA** — Google Interactive Media Ads (VMAP, VAST, server-side ad rules, advanced ad topics); iOS and tvOS.
- **DAI** — Google Dynamic Ad Insertion: a single server-stitched stream for VOD or live content; iOS and tvOS.
- **SSAI** — Brightcove Server-Side Ad Insertion, including Dynamic Delivery playback and a Server-Side Live + IMA pre-roll example (`SLS-IMA`); iOS and tvOS.
- **FreeWheel** — ads managed by FreeWheel (linear and companion). Requires the FreeWheel SDK; see the FreeWheel README.
- **Pulse** — ads managed by INVIDI Technologies Pulse; iOS and tvOS. Requires the Pulse SDK; see the Pulse README.

#### DRM & Offline (`DRM`, `Offline`)

- **DRM** — FairPlay-protected playback using the FairPlay support built into the core BrightcovePlayerSDK framework. See the note below.
- **Offline** — downloading offline-enabled HLS videos (including FairPlay-protected) and playing them back with or without a network connection. iOS does **not** allow video downloads on a simulator, so develop on an actual device.

##### A note about the DRM (FairPlay) sample

In the FairPlay sample there are references to `FairPlayPublisherId` and `FairPlayApplicationId`. These are FairPlay credentials that Brightcove does not provide; they are acquired through Apple directly. iOS does **not** allow FairPlay-protected video to display on a simulator, so develop on an actual device.

#### Casting (`Cast`)

The `Cast` samples direct streaming video to a Chromecast device using the Google Cast plugin. `BasicCastPlayer` demonstrates a custom cast manager with `BCOVGoogleCastManager`; `BrightcoveCastReceiver` supports more features such as DRM-protected video, SSAI, and HLSv3 or superior.

#### Captions (`Captions`)

- **BasicSidecarSubtitlesPlayer** — adding WebVTT subtitles to an HLS manifest at runtime, using the SidecarSubtitles support in the core BrightcovePlayerSDK framework.
- **SubtitleRendering** — parsing and displaying WebVTT so you can customize the positioning and appearance of subtitles.

#### Analytics (`Analytics`)

The `Analytics` sample demonstrates tracking analytics with the Omniture (Adobe) plugin. Requires the Adobe SDKs; see the README.

#### Declarative UI (`SwiftUI`)

The `SwiftUI` samples host the Brightcove player in a SwiftUI app:

- **SwiftUIPlayer** — basic playback in SwiftUI, including presenting content in fullscreen over a SwiftUI `TabView`.
- **CustomControls** — building your own custom playback controls in SwiftUI.
- **SwiftUIPlayerIMA** — integrating Google IMA ads in a SwiftUI player.

#### Host Frameworks (`Flutter`, `ReactNative`)

The `Flutter` and `ReactNative` samples show how to integrate the Brightcove SDK into cross-platform apps. Both use CocoaPods (see their READMEs and the CocoaPods note above).

#### Co-watching (`SharePlay`)

The `SharePlay` sample uses Apple's GroupActivities framework to synchronize Brightcove playback across participants in a FaceTime call. iOS only.

### Feature Highlights

- An example of creating a `BCOVPlaybackSessionConsumer` can be found in the `Offline/OfflinePlayer` and `PlayerUI/CustomControls` sample apps.
- Picture-in-Picture functionality can be found in the `Player/VideoCloudBasicPlayer` sample app.
- An example of configuring AVAudioSession based on the `mute` state of AVPlayer can be found in the `Player/VideoCloudBasicPlayer` sample app.
- An example of setting up lock screen playback controls can be found in the `Player/VideoCloudBasicPlayer` sample app.
- An example of creating a `BCOVPlaybackController` using a view strategy can be found in the `PlayerUI/ViewStrategy` sample app.
- An example of creating a custom Audio & Subtitles menu can be found in `PlayerUI/CustomControls`.

### Localization

The Brightcove iOS SDK is localized for the following languages:

* English - en
* Arabic - ar
* German - de
* Spanish - es
* French - fr
* Japanese - ja
* Korean - ko
* Chinese traditional - zh-hant
* Chinese simplified - zh-hans

The following sample projects take advantage of this localization:

* Player/VideoCloudBasicPlayer
* Player/AppleTV-tvOS
* IMA/BasicIMAPlayer-iOS
* SSAI/BasicSSAIPlayer-iOS

[cocoapods]: http://www.cocoapods.org
