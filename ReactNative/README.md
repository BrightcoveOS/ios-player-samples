# React Native

Learn more about [React Native](https://reactnative.dev/).

This sample shows how to integrate React Native with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both React Native and the Brightcove SDK; this is not a React Native tutorial and Brightcove cannot provide support for React Native. The React Native [development environment](https://reactnative.dev/docs/environment-setup) must be set up first.

This sample uses **CocoaPods** (see the [CocoaPods note in the root README](../README.md#cocoapods-flutter-and-reactnative-samples-only), including the deprecation timeline and the `BRIGHTCOVE_LOCAL_SDK` switch).

## Prerequisites

1. Node.js (required by the Podfile's `use_native_modules!`)
1. yarn
1. CocoaPods 1.11+
1. Xcode 15.0+
1. iOS 14.0+

## Architecture

The native Brightcove player is exposed to React Native as a **native view component**:

- **Native host** (`ios/ReactNativePlayer/`): `BCOVVideoPlayerManager` is an `RCTViewManager` registered to JS as `BCOVVideoPlayer`; its `view()` returns a `BCOVVideoPlayer` `UIView` that wraps a `BCOVPlaybackController` and holds the account / policy / video. It exports the events `onReady` / `onProgress` / `onEvent` and the methods `playPause`, `thumbnailAtTime`, `onSlidingComplete`.
- **JS side** (`src/`): `BCOVVideoPlayer.tsx` wraps the native component with `requireNativeComponent('BCOVVideoPlayer')`; `VideoPlayer.tsx` renders it, calls the native methods via `NativeModules`, and overlays a JS `Controls` component.

The integrated Brightcove pod is `Brightcove-Player-IMA` (declared via the `brightcove_pod` helper, which also pulls in `Brightcove-Player-Core`).

## Running the sample

1. Install the JS dependencies with `yarn install`.
1. Go to the `ios` folder and run `pod install`.
1. Start the Metro server with `yarn start`.
1. Open `ReactNativePlayer.xcworkspace`.
1. Run on a simulator or physical device.

## Using the Brightcove IMA plugin

The project is configured to support the IMA plugin. The IMA-related code is commented out by default so the project builds without exercising the IMA dependency; uncomment it to enable IMA ads.
