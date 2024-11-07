# Custom Controls App

This sample is intended to show you how to use your own custom playback controls with the Brightcove-Player-SDK. One advantage to using Brightcove's `BCOVPUIPlayerView` is that you get VoiceOver support out of the box. If you implement your own custom controls you will be responsible for providing accessiblity support. 

This sample also demonstrates how to set up a custom Audio & Subtitles menu to allow users to select alternate audio and text tracks for a video. When the current `BCOVPlaybackSession` is set on `ClosedCaptionMenuController` the `closedCaptionButton` on  `ControlsViewController` will be enabled or disabled depending on the availability of text and/or audio tracks.

You may wish to add `accessibilityLabel` values to each of your buttons in addition to preventing playback controls from auto-hiding when VoiceOver is active, in addition to implementing the `func accessibilityActivate() -> Bool` in your custom control's view so that you can hide or show controls when a user double taps with VoiceOver enabled.

For more information about implementing accessibility and VoiceOver support for your project see Apple's [Supporting VoiceOver in Your App](https://developer.apple.com/documentation/uikit/accessibility_for_ios_and_tvos/supporting_voiceover_in_your_app). 
