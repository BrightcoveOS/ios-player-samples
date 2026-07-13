# Basic FreeWheel Player

The FreeWheel AdManager SDK is not distributed via Swift Package Manager; you must manually add it to the application target of your project. It can be downloaded from the [FreeWheel website](https://hub.freewheel.tv/display/techdocs/AdManager+SDK+Integration+Downloads).

_Ensure that you are using the "AdManager Dynamic Build" version of AdManager._

To add the AdManager xcframework to the BasicFreeWheelPlayer sample project

1. Open `ios-player-samples/FreeWheel/BasicFreeWheelPlayer.xcodeproj` in Xcode. Swift Package Manager resolves the Brightcove SDK automatically on the first build.

1. In the Project Navigator, expand the BasicFreeWheelPlayer project.

1. In Finder, select your `AdManager.xcframework` and drag it to the Frameworks group in the Xcode Project Navigator. When prompted, ensure that the AdManager.xcframework is being added to the BasicFreeWheelPlayer target.

1. In Xcode under "Frameworks, Libraries and Embedded Content" set AdManager.xcframework to "Embed & Sign".

1. In the Project Navigator, select the BasicFreeWheelPlayer project. At the top of the Xcode Editor Area, choose Build Settings. Search for "Framework Search Paths". Add a framework search path that is the parent folder of your AdManager.xcframework (probably `iOS_AdManagerDistribution`).
