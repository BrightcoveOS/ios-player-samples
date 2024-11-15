# React Native

Learn more about [React Native](https://reactnative.dev/).

This sample shows how to integrate React Native with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both React Native and the Brightcove SDK. This sample is not a React Native tutorial and Brightcove cannot provide support for React Native. To build the React Native Sample App, the [development environment](https://reactnative.dev/docs/environment-setup) need to be set.

## Prerequisites

1. yarn
1. CocoaPods 1.10+
1. Xcode 13.0+
1. iOS 13.4+

## Running Sample App

1. Install node dependencies using `yarn install`.
1. Go to _ios_ project and run the command `pod install`.
1. Start the react native server with `yarn start` script from `package.json`.
1. Open `ReactNativePlayer.xcworkspace`.
1. Run the project using simulator or physical device.

### Using the Brightcove IMA Plugin

The ReactNativePlayer sample project is configured to support the IMA Plugin for Brightcove Player SDK for iOS. By default the IMA related code is commented out so that you can build the project without the IMA SDK dependency.

If you wish to enable the IMA functionality you will need to uncomment the IMA specific code.
