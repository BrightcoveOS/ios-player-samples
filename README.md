Brightcove Player SDK for iOS Samples
=====================================
Learn more about the [Brightcove Native Player SDKs](https://support.brightcove.com/brightcove-native-player-sdks).

ios-player-samples.git is a collection of sample applications for the Brightcove Player SDKs for iOS and tvOS, organized by subject area. An installation of [CocoaPods][cocoapods] 1.0.0 or higher is required to download the sample dependencies.

### Prerequisites

1. CocoaPods 1.0+
1. Xcode 10.0+

### About CocoaPods
To ensure you are using the latest releases of the Brightcove software components, update your Podspec repository before building any of the sample applications by running the following on the command line:

```
pod repo update
```

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

FairPlay samples demonstrate how to use the FairPlay plugin in Swift.

#### FairPlayIMAPlayer
To see an example of using FairPlay with IMA, refer to the FairPlayIMAPlayer sample app in the IMA folder.

#### A note about the FairPlay sample apps
In both of the FairPlay sample apps, there are references to `FairPlayPublisherId` and `FairPlayApplicationId`. These terms refer to FairPlay credentials that Brightcove does not provide, which are instead acquired through Apple directly.

#### FreeWheel

FreeWheel samples demonstrate how to use the FreeWheel plugin.

#### GoogleCast

BasicCastPlayer demonstrates how to use the Google Cast plugin.

#### IMA

IMA samples demonstrate how to use the IMA plugin. These are intended to cover use cases like VMAP, VAST, Server Side Ad rules, and advanced ad topics.

#### Offline

OfflinePlayer demonstrates downloading offline-enabled HLS videos and playing them back with or without a network connection. Xcode 9.0+ is required to build and run this sample app.

#### Omniture

Omniture samples demonstrate how to use the Omniture plugin.

#### OUX

OUX samples demonstrate how to use the OUX plugin.

#### Player

Player samples demonstrate how to use the core SDK. These are intended to cover use cases like custom controls, analytics, and playback.

#### PlayerUI

PlayerUICustomization demonstrates modification of the BCOVPlayerUI controls and customization of VoiceOver properties for accessibility. 

#### SidecarSubtitles

SidecarSubtitles samples demonstrate how to use the sidecarSubtitles plugin.

#### SSAI

BasicSSAIPlayer demonstrates how to use the OUX plugin for server-side-ad-integration.

[cocoapods]: http://www.cocoapods.org
