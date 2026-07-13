# SwiftUI Custom Controls

A SwiftUI sample app that demonstrates building a fully custom set of playback controls on top of the Brightcove Native Player SDK for iOS, instead of relying on the SDK's built-in `BCOVPUIPlayerView` controls.

It shows how to:

- Drive play/pause and a custom scrubber from `BCOVPlaybackController` delegate callbacks (progress, duration, and buffered range).
- Render a thumbnail preview image while scrubbing, sourced from the video's thumbnail (WebVTT) text track.
- Auto-hide the controls during playback and toggle them with a tap.

## See also

- `SwiftUI/SwiftUIPlayer/` — a SwiftUI player without custom controls.
- `SwiftUI/SwiftUIPlayerIMA/` — SwiftUI with Google IMA ads.
