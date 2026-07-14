# React Native

This sample shows how to integrate React Native with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both React Native and the Brightcove SDK; this is not a React Native tutorial and Brightcove cannot provide support for React Native. The React Native [development environment](https://reactnative.dev/docs/environment-setup) must be set up first.

This sample uses CocoaPods (see the [CocoaPods note in the root README](../README.md#cocoapods-flutter-and-reactnative-samples-only)).

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Node.js, yarn, CocoaPods 1.11+, Xcode 15.0+.
- **Extra SDKs:** the Brightcove SDK via CocoaPods (the `Brightcove-Player-IMA` pod, which pulls in `Brightcove-Player-Core`).

## Setup

1. Install the JS dependencies with `yarn install`.
2. In `ios`, run `pod install`.
3. Start the Metro server with `yarn start`.
4. Open `ReactNativePlayer.xcworkspace` and run on a simulator or device.

## Architecture

The native Brightcove player is exposed to React Native as a native view component. On the native side (`ios/ReactNativePlayer/`), a view manager registers a `BCOVVideoPlayer` component and exports its events and methods; on the JS side (`src/`), `requireNativeComponent('BCOVVideoPlayer')` renders it with a JS controls overlay.

## Using the Brightcove IMA plugin

The project is configured to support the IMA plugin. The IMA-related code is commented out by default so the project builds without exercising the IMA dependency; uncomment it to enable IMA ads.
