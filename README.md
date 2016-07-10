Brightcove Player SDK for iOS Samples
=====================================
Learn more about the [Brightcove Native Player SDKs](http://docs.brightcove.com/en/video-cloud/mobile-sdks/index.html).

These are a collection of sample applications for the Brightcove Player SDKs for iOS and tvOS, organized by subject area. An installation of [CocoaPods][cocoapods] is required to download sample dependencies.

### Prerequisites

1. CocoaPods 1.0+
1. Xcode 7.0+

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

##### FairPlay

FairPlay samples demonstrate how to use the FairPlay plugin in Swift.

##### FairPlayIMAPlayer
To see an example of using FairPlay with IMA, refer to the FairPlayIMAPlayer sample app in the IMA folder.

###### A note about the FairPlay sample apps
In both of the FairPlay sample apps, there are references to `FairPlayPublisherId` and `FairPlayApplicationId`. These terms refer to FairPlay credentials that Brightcove does not provide, which are instead acquired through Apple directly.

##### FreeWheel

FreeWheel samples demonstrate how to use the FreeWheel plugin.

##### IMA

IMA samples demonstrate how to use the IMA plugin. These are intended to cover use cases like VMAP, VAST, Server Side Ad rules, and advanced ad topics.

##### Omniture

Omniture samples demonstrate how to use the Omniture plugin.

##### OUX

OUX samples demonstrate how to use the OUX plugin.

##### Player

Player samples demonstrate how to use the core SDK. These are intended to cover use cases like custom controls, analytics, and playback.

#### SidecarSubtitles

SidecarSubtitles samples demonstrate how to use the sidecarSubtitles plugin.

[cocoapods]: http://www.cocoapods.org
