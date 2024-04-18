Brightcove Player SDK for iOS Samples
=====================================

Learn more about the [Brightcove Native Player SDKs](https://sdks.support.brightcove.com/getting-started/brightcove-native-player-sdks.html).

ios-player-samples.git is a collection of sample applications for the Brightcove Player SDKs for iOS and tvOS, organized by subject area. An installation of [CocoaPods][cocoapods] 1.0.0 or higher is required to download the sample dependencies.

### Prerequisites

1. CocoaPods 1.11+
1. Xcode 13.0+, Xcode 14.0+ is recommended (refer to _About Bitcode_ below).
1. iOS 12.0+ or tvOS 12.0+

An Apple Developer Program account is required to run any sample app on a physical device. In order to provision your device, edit the sample app bundle identifier to make it unique to your organization.

### About CocoaPods

To ensure you are using the latest releases of the Brightcove software components, update your Podspec repository before building any of the sample applications by running the following on the command line:

```
pod repo update
```

### About Bitcode

The ENABLE_BITCODE setting has been removed from all sample projects and the default value of the IDE is used instead. Xcode 14.0 has deprecated bitcode and the default setting is NO. The default bitcode setting in Xcode 13 is YES.

Brightcove SDK versions 6.10.6 and above do not include bitcode images. If you are building sample projects using Xcode 13.4.1 or earlier, you must manually disable bitcode in your project settings.

From the [Xcode 14 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes):

> Starting with Xcode 14, bitcode is no longer required for watchOS and tvOS applications, and the App Store no longer accepts bitcode submissions from Xcode 14.
> 
> Xcode no longer builds bitcode by default and generates a warning message if a project explicitly enables bitcode: “Building with bitcode is deprecated. Please update your project and/or target settings to disable bitcode.” The capability to build with bitcode will be removed in a future Xcode release. IPAs that contain bitcode will have the bitcode stripped before being submitted to the App Store. Debug symbols for past bitcode submissions remain available for download. (86118779)

### About Swift

The Swift sample apps are written in Swift language version 4.2.

### Instructions

Unless otherwise instructed, samples can be run by following these steps:

1. From the project directory, run `pod install`.
1. Open the corresponding `.xcworkspace` file.
1. Where the Podfile's pod directives do not specify that a dynamic framework is being installed, there is some additional setup required to build and run the project:
    - Locate the `bcovpuiiconfont.ttf` file in the Pods/Brightcove-Player-SDK/ios/BrightcovePlayerSDK.framework folder.
    - Add this file to your Xcode project listing so that the font file is copied into the app bundle.
    - In the built app's bundle, the font file should end up at the same level as the app's Info.plist file.
    - The font file supplies some of the BrightcovePlayerUI interface elements, but it does not need to be listed in the plist itself.
1. There are README.md files in several of the samples that provide additional setup steps that are specific to those examples.

Note: If you intend to use these samples offline, be sure to run Cocoapods before going offline in order to download the required dependencies.

### Samples

#### FairPlay

FairPlay samples demonstrate how to play protected videos using FairPlay plugin that is integrated into the core BrightcovePlayerSDK framework. 

#### A note about the FairPlay sample apps

In both of the FairPlay sample apps, there are references to `FairPlayPublisherId` and `FairPlayApplicationId`. These terms refer to FairPlay credentials that Brightcove does not provide, which are instead acquired through Apple directly.

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

#### SidecarSubtitles

SidecarSubtitles sample demonstrates how to add WebVTT subtitles to an HLS manifest from within an iOS/tvOS app using SidecarSubtitles plugin that is integrated into the core BrightcovePlayerSDK framework.

#### SSAI

SSAI samples demonstrate how to use the SSAI plugin. These are intended to cover playback of Dynamic Delivery with or without Server-Side Ad Insertion, and play pre-rolls using Google IMA for SSAI Live Streams.

#### SubtitleRendering

SubtitleRendering samples demonstrate how to parse and display WEBVTT files so that you can customize the positioning and look of your subtitles.

#### SwiftUIPlayer

SwiftUIPlayer demonstrates how to use `BCOVUIPlayerView` and `AVPlayerViewController` with SwiftUI and how to present content in fullscreen over a SwiftUI TabView.

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
* IMA/BasicIMAPlayer
* SSAI/BasicSSAIPlayer

[cocoapods]: http://www.cocoapods.org
