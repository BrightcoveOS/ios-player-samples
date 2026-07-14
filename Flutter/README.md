# Flutter

This sample shows how to integrate Flutter with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both Flutter and the Brightcove SDK; this is not a Flutter tutorial and Brightcove cannot provide support for Flutter. An installation of [Flutter](https://docs.flutter.dev/get-started/install/macos) is required.

This sample uses CocoaPods (see the [CocoaPods note in the root README](../README.md#cocoapods-flutter-and-reactnative-samples-only)).

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Flutter SDK, CocoaPods 1.11+, Xcode 15.0+.
- **Extra SDKs:** the Brightcove SDK via CocoaPods (the `Brightcove-Player-IMA` pod, which pulls in `Brightcove-Player-Core`).

## Setup

1. In `flutter_bcov`, run `flutter pub get`.
2. Run `pod install` (in `Flutter/`).
3. Open `FlutterPlayer.xcworkspace` and run on a simulator or device.

To hot-reload the Flutter widgets, run `flutter attach -d '<device-id>' --app-id <your-bundle-id>` (the bundle id is `com.brightcove.player.samples.FlutterPlayer` by default).

## Architecture

The native Brightcove player is embedded as a platform view. On the native side (`FlutterPlayer/`), a plugin registers a platform-view factory under the view type `bcov.flutter/player_view`; on the Dart side (`flutter_bcov/`), a `UiKitView` hosts that native view with Flutter-drawn controls on top — see the [`flutter_bcov` README](flutter_bcov/). The two sides communicate over a method channel (Dart → native) and an event channel (native → Dart).

## Using the Brightcove IMA plugin

The project is configured to support the IMA plugin. The IMA-related code is commented out by default so the project builds without exercising the IMA dependency; uncomment it to enable IMA ads.
