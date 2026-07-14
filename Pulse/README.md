# Pulse

The `Pulse` samples demonstrate ad playback with INVIDI Technologies Pulse.

## Requirements

- **Platform:** iOS and tvOS.
- **Minimum OS:** iOS 14.0, tvOS 15.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** the INVIDI Pulse SDK, added manually — iOS also needs the INVIDI Open Measurement SDK; tvOS needs the Pulse tvOS framework.

## Setup

Open the sample's `.xcodeproj` in Xcode; Swift Package Manager resolves the Brightcove SDK on the first build. Download the INVIDI frameworks and add them to the application target before building — iOS SDKs [here](https://service.videoplaza.tv/proxy/ios-sdk/2/latest), tvOS SDK [here](https://service.videoplaza.tv/proxy/tvos-sdk/2/latest). The samples ship with a working Brightcove demo account and a test Pulse host — replace the host with your own.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| [`BasicPulsePlayer-iOS`](BasicPulsePlayer-iOS/) | iOS | A table of 12 ad scenarios (pre/mid/post-roll, skippable, frequency capping, pause ads, mid-session extension, error cases) with a companion slot |
| [`BasicPulsePlayer-tvOS`](BasicPulsePlayer-tvOS/) | tvOS | Pulse playback on tvOS with fixed content metadata and midroll positions |
