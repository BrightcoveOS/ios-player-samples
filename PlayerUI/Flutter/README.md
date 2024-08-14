# Flutter

Learn more about [Flutter](https://flutter.dev/).

This sample shows how to integrate Flutter with the Brightcove Player SDKs for iOS. The reader is expected to be familiar with both Flutter and the Brightcove SDK. This sample is not a Flutter tutorial and Brightcove cannot provide support for Flutter. An installation of [Flutter](https://docs.flutter.dev/get-started/install/macos) is required to run the sample app.

## Prerequisites

1. Flutter SDK
1. CocoaPods 1.10+
1. Xcode 13.0+
1. iOS 12.0+

## About Flutter

After you installed Flutter in your machine, run `flutter doctor` to verify that you have installed all the necessary dependencies. The minimium dependencies are:

- Flutter SDK.
- Xcode.
- [Visual Studio Code](https://code.visualstudio.com/) (recommended) and [Flutter Plugin for VS Code](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter).

## About Flutter Sample App

### flutter_bcov

The *flutter_bcov* folder contains the package of the plugin.

## Running Sample App

1. Go to *flutter_bcov* and run the command `flutter pub get`.
1. Go to *objc* or *swift* project and run the command `pod install`.
1. Open `FlutterPlayer.xcworkspace` (objc or swift).
1. Run the project using simulator or physical device.

## Debugging Sample App

1. Run your app using Xcode.
1. Run the command `flutter doctor -v` in your terminal (in the *flutter_app* folder) to get the *device* where your app is running.
1. Run the command `flutter attach -d 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' --app-id com.yourcompany.FlutterPlayer` using the *id* retrieved in the previous step and the *Bundle Identifier*, for this example the bundle identifier is *com.yourcompany.FlutterPlayer*.
1. You can restart or reload the widgets in your terminal.
1. Using *Visual Studio Code* you can debug the variables or adding break points for the Flutter code.

### Using the Brightcove IMA Plugin

The FlutterPlayer sample project is configured to support the IMA Plugin for Brightcove Player SDK for iOS. By default the IMA related code is commented out so that you can build the project without the IMA SDK depdendency. 

If you wish to enable the IMA functionality you will need to uncomment the IMA specific code.