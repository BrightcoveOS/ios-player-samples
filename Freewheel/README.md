# Basic Freewheel Player

The Freewheel AdManager SDK is not installed by CocoaPods; You must manually add it to the application target of your project.

To add the AdManager framework to the BasicFreewheelPlayer sample project:

1. cd to `ios-player-samples/Freewheel/BasicFreewheelPlayer/objc` and install the Brightcove Player CocoaPods by running the following from the command line.

```
pod install
```

1. Open the BasicFreeqwheelPlayer.xcworkspace document.

1. In the Project Navigator, expand the BasicFreewheelPlayer project.

1. In Finder, select your AdManager.framework and drag it to the Frameworks group in the Xcode Project Navigator. When prompted, ensure that the AdManager.framework is being added to the BasicFreewheelPlayer target.

1. **If you are using Xcode 9.0**, you must take an extra step to add the AdManager.framework to your application target. Select the AdManager.framework in the Project Navigator and  open the File Inspector. Make certain that BasicFreewheelPlayer is checked for Target Membership.
 
1. In the Project Navigator, select the BasicFreewheelPlayer project. At the top of the Xcode Editor Area, choose Build Settings. Search for "Framework Search Paths". Add a framework search path that is the parent folder of your AdManager.framework (probably `iOS_AdManagerDistribution`).
