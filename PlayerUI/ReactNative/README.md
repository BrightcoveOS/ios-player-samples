# React Native

Learn more about [React Native](https://reactnative.dev/).

This sample shows how to integrate React Native with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both React Native and the Brightcove SDK. This sample is not a React Native tutorial and Brightcove cannot provide support for React Native. To build the React Native Sample App, the [development environment](https://reactnative.dev/docs/environment-setup) need to be set.

## Prerequisites

1. npm or yarn
1. CocoaPods 1.10+
1. Xcode 13.0+
1. iOS 13.4+

## Running Sample App

1. Install node dependencies using `npm` or `yarn`.
1. Go to *objc* or *swift* project and run the command `pod install`.
1. Update the `react-native.config.js` file according the `sourceDir` you have choosen under `ios` in the previous step
1. Start the react native server with `npm start` script from `package.json`.
1. Open `PlayerReactNative.xcworkspace` (objc or swift).
1. Run the project using simulator or physical device.
