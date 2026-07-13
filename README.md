Brightcove Player SDK for iOS Samples
=====================================

Learn more about the [Brightcove Native Player SDKs](https://sdks.support.brightcove.com/getting-started/brightcove-native-player-sdks.html).

ios-player-samples.git is a collection of sample applications for the Brightcove Player SDKs for iOS and tvOS, organized by subject area. The sample apps consume the Brightcove SDK through [Swift Package Manager](https://www.swift.org/documentation/package-manager/). The `PlayerUI/Flutter` and `PlayerUI/ReactNative` samples instead use [CocoaPods][cocoapods].

### Prerequisites

1. Xcode 15.0+ (the `SwiftUI/SwiftUIPlayerIMA` sample requires Xcode 16.0+)
1. iOS 14.0+ or tvOS 15.0+ (some samples require a higher deployment target — see the sample's own README)
1. [CocoaPods][cocoapods] 1.11+ — only for the `PlayerUI/Flutter` and `PlayerUI/ReactNative` samples

An Apple Developer Program account is required to run any sample app on a physical device. In order to provision your device, edit the sample app bundle identifier to make it unique to your organization.

### Swift Package Manager

Most samples consume the Brightcove SDK through Swift Package Manager. Open the sample's `.xcodeproj` in Xcode and the required packages are resolved automatically on the first build — there is no separate install step.

### CocoaPods (Flutter and ReactNative samples only)

> **Note:** Brightcove's CocoaPods distribution is deprecated as of SDK 7.2.15 and will stop receiving updates once the CocoaPods Trunk becomes read-only (expected late 2026). New integrations should use Swift Package Manager; these two samples remain on CocoaPods until their framework integrations migrate.

The `PlayerUI/Flutter` and `PlayerUI/ReactNative` samples use CocoaPods. To ensure you are using the latest releases of the Brightcove software components, update your Podspec repository before building them:

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

The `PlayerUI/Flutter` and `PlayerUI/ReactNative` samples use CocoaPods instead — run `pod install` and open the generated `.xcworkspace`, as described in their READMEs.

Note: package resolution requires network access on the first build. Once resolved, Xcode caches the packages for offline use.

### Samples

#### DAI

DAI samples demonstrate how to use Google's Dynamic Ad Insertion (DAI) to request a single stream that stitches ads into the content server-side, for both VOD and live content. iOS and tvOS variants are provided.

#### FairPlay

The FairPlay sample demonstrates how to play protected videos using the FairPlay plugin that is integrated into the core BrightcovePlayerSDK framework.

#### A note about the FairPlay sample app

In the FairPlay sample app, there are references to `FairPlayPublisherId` and `FairPlayApplicationId`. These terms refer to FairPlay credentials that Brightcove does not provide, which are instead acquired through Apple directly.

iOS does **not** allow FairPlay-protected video to display in a simulator so it's important to develop on an actual device.

#### FreeWheel

FreeWheel samples demonstrate how to play ads managed by FreeWheel. These are intended to cover the basic configuration to retrieve linear and companion ads.

#### GoogleCast

GoogleCast samples demonstrate how to extend your app to direct its streaming video to a Chromecast device using the Google Cast plugin. The `BasicCastPlayer` app is intended to cover use of a custom cast manager and BCOVGoogleCastManager. The `BrightcoveCastReceiver` app supports more features such DRM protected videos, SSAI and HLSv3 or superior.

#### IMA

IMA samples demonstrate how to play ads managed by Google Interactive Media Ads (IMA). These are intended to cover use cases like VMAP, VAST, Server Side Ad rules, and advanced ad topics.

#### Offline

Offline samples demonstrate downloading offline-enabled HLS videos and playing them back with or without a network connection.

iOS does **not** allow video downloads to a simulator so it's important to develop on an actual device.

#### Omniture

Omniture sample demonstrates how to track analytics using the Omniture plugin.

#### Player

Player samples demonstrate how to use the core SDK. These are intended to cover use cases like custom controls, analytics, and playback.

#### PlayerUI

PlayerUI samples demonstrate how to customize the player look and feel. These are intended to cover the modification of the BCOVPlayerUI, the customization of VoiceOver properties for accessibility and the use of the view strategy.

#### Pulse

Pulse samples demonstrate how to play ads managed by INVIDI Technologies Pulse. These are intended to cover different configurations for the content.

#### SharePlay

SharePlay sample demonstrates how to use Apple's GroupActivities framework to synchronize Brightcove playback across participants in a FaceTime call.

#### SidecarSubtitles

SidecarSubtitles sample demonstrates how to add WebVTT subtitles to an HLS manifest from within an iOS/tvOS app using SidecarSubtitles plugin that is integrated into the core BrightcovePlayerSDK framework.

#### SSAI

SSAI samples demonstrate how to use the SSAI plugin. These are intended to cover playback of Dynamic Delivery with or without Server-Side Ad Insertion, and play pre-rolls using Google IMA for SSAI Live Streams.

#### SubtitleRendering

SubtitleRendering samples demonstrate how to parse and display WEBVTT files so that you can customize the positioning and look of your subtitles.

#### SwiftUI

The SwiftUI samples demonstrate how to host the Brightcove player in a SwiftUI app:

- **SwiftUIPlayer** — basic playback in SwiftUI, including presenting content in fullscreen over a SwiftUI `TabView`.
- **CustomControls** — building your own custom playback controls in SwiftUI.
- **SwiftUIPlayerIMA** — integrating Google IMA ads in a SwiftUI player.

### Feature Highlights

- An example of creating a `BCOVPlaybackSessionConsumer` can be found in the `OfflinePlayer` and `CustomControls` sample apps.
- Picture-in-Picture functionality can be found in the `VideoCloudBasicPlayer` sample app. 
- An example of configuring AVAudioSession based on the `mute` state of AVPlayer can be found in the `VideoCloudBasicPlayer` sample app. 
- An example of setting up lock screen playback controls can be found in the  `VideoCloudBasicPlayer` sample app.
- An example of creation a `BCOVPlaybackController` using a view strategy can be found in the `PlayerUI` section.
- An example of creating a custom Audio & Subtitles menu can be found in `CustomControls`

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
* Player/AppleTV
* IMA/BasicIMAPlayer-iOS
* SSAI/BasicSSAIPlayer-iOS

[cocoapods]: http://www.cocoapods.org
