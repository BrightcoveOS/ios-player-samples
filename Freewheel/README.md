# Basic Freewheel Player

The Freewheel AdManager SDK is not installed by CocoaPods; You must manually add it to the application target of your project. *Ensure that you are using the "AdManager Dynamic Build" version of AdManager.*

To add the AdManager xcframework to the BasicFreewheelPlayer sample project:

1. cd to `ios-player-samples/Freewheel/BasicFreewheelPlayer/objc` and install the Brightcove Player CocoaPods by running the following from the command line.

```
pod install
```

1. Open the BasicFreewheelPlayer.xcworkspace document.

1. In the Project Navigator, expand the BasicFreewheelPlayer project.

1. In Finder, select your AdManager.xcframework and drag it to the Frameworks group in the Xcode Project Navigator. When prompted, ensure that the AdManager.xcframework is being added to the BasicFreewheelPlayer target.

1. In Xcode under "Frameworks, Libraries and Dmbedded Content" set AdManager.xcframework to "Embed & Sign".
 
1. In the Project Navigator, select the BasicFreewheelPlayer project. At the top of the Xcode Editor Area, choose Build Settings. Search for "Framework Search Paths". Add a framework search path that is the parent folder of your AdManager.framework (probably `iOS_AdManagerDistribution`).
