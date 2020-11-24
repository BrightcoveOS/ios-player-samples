# Basic Omniture Player

### ADBMobileConfig.json

Use of this player sample requires an Adobe analytics account and the custom ADBMobileConfig.json file associated with that account. For this player sample to run correctly, you must replace the included sample ADBMobileConfig.json file with your own.

### Adobe SDKs

The Adobe analytics SDKs are **not** included in this sample project. To add them, open a Terminal window, cd to the `BasicOmniturePlayer/objc` folder if using the Objective-C project, or the `BasicOmniturePlayer/swift` folder if using Swift, and run these `git` commands:

```
git clone -b v4.14.1-iOS --single-branch https://github.com/Adobe-Marketing-Cloud/mobile-services.git
git clone -b ios-v2.0.1 --single-branch https://github.com/Adobe-Marketing-Cloud/video-heartbeat-v2.git
```

### Brightcove SDKs

Next, install the CocoaPods.

```
pod install
```

Open, build and run `BasicOmniturePlayer.xcworkspace`.
