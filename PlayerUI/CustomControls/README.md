# Custom controls — UIKit (CustomControls)

Builds a complete set of playback controls in UIKit instead of using `BCOVPUIPlayerView`. The custom `ControlsViewController` is registered with `playbackController.add(...)` as a session consumer, and a custom Audio & Subtitles menu (`ClosedCaptionMenuController`) enables or disables the CC button based on the audio and text tracks available on the current `BCOVPlaybackSession`.

## Key files

| File | Responsibility |
|---|---|
| `CustomControls/ViewController.swift` | Playback controller setup, video fetch, fullscreen presentation |
| `CustomControls/ControlsViewController.swift` | The custom control bar (play/pause, scrubber, labels, CC button, auto-hide) |
| `CustomControls/ClosedCaptionMenuController.swift` | Audio / subtitle track selection |

## Accessibility

`BCOVPUIPlayerView` provides VoiceOver support out of the box; with custom controls that responsibility is yours. Add `accessibilityLabel` values to your buttons, prevent controls from auto-hiding while VoiceOver is active, and implement `accessibilityActivate()` so a VoiceOver double-tap can show or hide the controls. See Apple's [Supporting VoiceOver in Your App](https://developer.apple.com/documentation/uikit/accessibility_for_ios_and_tvos/supporting_voiceover_in_your_app).

For the SwiftUI equivalent, see [`SwiftUI/CustomControls`](../../SwiftUI/CustomControls/). See the [UI Customization README](../) for shared setup.
