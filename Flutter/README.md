# Flutter

Learn more about [Flutter](https://flutter.dev/).

This sample shows how to integrate Flutter with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both Flutter and the Brightcove SDK; this is not a Flutter tutorial and Brightcove cannot provide support for Flutter. An installation of [Flutter](https://docs.flutter.dev/get-started/install/macos) is required to run the sample.

This sample uses **CocoaPods** (see the [CocoaPods note in the root README](../README.md#cocoapods-flutter-and-reactnative-samples-only), including the deprecation timeline and the `BRIGHTCOVE_LOCAL_SDK` switch).

## Prerequisites

1. Flutter SDK
1. CocoaPods 1.11+
1. Xcode 15.0+
1. iOS 14.0+

## Architecture

The native Brightcove player is embedded into Flutter as a **platform view**:

- **Native host** (`FlutterPlayer/`): `BCOVFlutterPlugin` registers a `FlutterPlatformViewFactory` (`BCOVVideoPlayerFactory`) under the view type `bcov.flutter/player_view`; `BCOVVideoPlayer.swift` wraps a `BCOVPlaybackController` and holds the account / policy / video.
- **Dart side** (`flutter_bcov/`): a `UiKitView` hosts that native view, with Flutter-drawn controls on top. See the [`flutter_bcov` README](flutter_bcov/).
- **Bridge:** a method channel `bcov.flutter/method_channel` (Dart → native: `playPause`, `seek`, `thumbnailAtTime`) and an event channel `bcov.flutter/event_channel` (native → Dart: playback and ad-sequence events).

The integrated Brightcove pod is `Brightcove-Player-IMA` (declared via the `brightcove_pod` helper, which also pulls in `Brightcove-Player-Core`).

## Running the sample

1. Go to `flutter_bcov` and run `flutter pub get`.
1. Run `pod install` (in `Flutter/`).
1. Open `FlutterPlayer.xcworkspace`.
1. Run on a simulator or physical device.

## Debugging the sample

1. Run the app from Xcode.
1. Run `flutter doctor -v` in your terminal to find the *device* your app is running on.
1. Run `flutter attach -d '<device-id>' --app-id <your-bundle-id>`, using the device id from the previous step and your app's bundle identifier (by default `com.brightcove.player.samples.FlutterPlayer`).
1. You can then hot-restart or hot-reload the Flutter widgets from the terminal, or debug from Visual Studio Code with breakpoints.

## Using the Brightcove IMA plugin

The project is configured to support the IMA plugin. The IMA-related code is commented out by default so the project builds without exercising the IMA dependency; uncomment it to enable IMA ads.
